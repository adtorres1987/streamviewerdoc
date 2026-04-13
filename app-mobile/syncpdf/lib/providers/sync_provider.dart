import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants.dart';
import '../models/sync_event.dart';
import '../services/sync_service.dart';

part 'sync_provider.g.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// The viewer state machine as described in the architecture spec.
///
///   synced → free          on HOST_DISCONNECTED
///   synced → disconnected  on network loss
///   free   → synced        on REJOIN_SYNC (explicit user opt-in)
///   disconnected → free    on reconnect (restores last personal position)
///   any    → closed        on SESSION_CLOSED (handled via BannerState)
enum ViewerSyncState { synced, free, disconnected }

/// Controls the bottom banner shown inside [PDFViewerScreen].
enum BannerState { hidden, hostDisconnected, hostReconnected, sessionClosed }

/// Snapshot of the host's position, used in the HOST_RECONNECTED banner.
class HostInfo {
  const HostInfo({
    required this.name,
    required this.page,
    required this.offsetY,
  });

  final String name;
  final int page;
  final double offsetY;
}

/// Immutable state for [SyncNotifier].
class SyncState {
  const SyncState({
    required this.isConnected,
    required this.viewerState,
    required this.bannerState,
    required this.participantCount,
    this.reconnectingHost,
    this.lastHostPage,
    this.lastHostOffset,
    this.joinHostPage,
  });

  final bool isConnected;
  final ViewerSyncState viewerState;
  final BannerState bannerState;
  final int participantCount;

  /// Populated when [BannerState.hostReconnected] is active.
  final HostInfo? reconnectingHost;

  /// Last known host position — set when host disconnects.
  final int? lastHostPage;
  final double? lastHostOffset;

  /// Host's page at the moment this viewer freshly joined.
  /// Non-null only when > 1.  Cleared once the viewer has acted on it.
  final int? joinHostPage;

  SyncState copyWith({
    bool? isConnected,
    ViewerSyncState? viewerState,
    BannerState? bannerState,
    int? participantCount,
    HostInfo? reconnectingHost,
    int? lastHostPage,
    double? lastHostOffset,
    int? joinHostPage,
    bool clearReconnectingHost = false,
    bool clearJoinHostPage = false,
  }) {
    return SyncState(
      isConnected: isConnected ?? this.isConnected,
      viewerState: viewerState ?? this.viewerState,
      bannerState: bannerState ?? this.bannerState,
      participantCount: participantCount ?? this.participantCount,
      reconnectingHost: clearReconnectingHost
          ? null
          : (reconnectingHost ?? this.reconnectingHost),
      lastHostPage: lastHostPage ?? this.lastHostPage,
      lastHostOffset: lastHostOffset ?? this.lastHostOffset,
      joinHostPage: clearJoinHostPage ? null : (joinHostPage ?? this.joinHostPage),
    );
  }

  static SyncState initial() => const SyncState(
        isConnected: false,
        viewerState: ViewerSyncState.synced,
        bannerState: BannerState.hidden,
        participantCount: 0,
      );
}

// ---------------------------------------------------------------------------
// SyncNotifier
// ---------------------------------------------------------------------------

@riverpod
class SyncNotifier extends _$SyncNotifier {
  final _syncService = SyncService();
  StreamSubscription<SyncEvent>? _eventSub;
  String? _currentRoomId;
  String? _currentRole; // 'host' | 'viewer'

  @override
  SyncState build() {
    // Clean up when the provider is disposed (e.g. when leaving the room).
    ref.onDispose(() {
      _eventSub?.cancel();
      _syncService.disconnect();
    });
    return SyncState.initial();
  }

  // --------------------------------------------------------------------------
  // Public stream — PDFViewerScreen listens here for position-changing events.
  // --------------------------------------------------------------------------

  /// Forwards all raw [SyncEvent]s so that [PDFViewerScreen] can react to
  /// scroll and context events without storing them in [SyncState].
  Stream<SyncEvent> get eventStream => _syncService.events;

  // --------------------------------------------------------------------------
  // Connect / disconnect
  // --------------------------------------------------------------------------

  /// Reads the JWT from secure storage, connects the WebSocket, and joins
  /// [roomId].  [role] must be either `'host'` or `'viewer'`.
  Future<void> connect(String roomId, String role) async {
    _currentRoomId = roomId;
    _currentRole = role;

    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: AppConstants.tokenStorageKey);
    if (jwt == null) return; // unauthenticated — router guard should prevent this

    _syncService.connect(jwt);

    // Subscribe to events before joining so no messages are missed.
    _eventSub?.cancel();
    _eventSub = _syncService.events.listen(_handleEvent);

    _syncService.joinRoom(roomId);
  }

  /// Tears down the WebSocket connection.
  /// State resets automatically via auto-dispose when the last watcher leaves.
  void disconnect() {
    _eventSub?.cancel();
    _syncService.disconnect();
    _currentRoomId = null;
    _currentRole = null;
  }

  // --------------------------------------------------------------------------
  // Scroll broadcasting
  // --------------------------------------------------------------------------

  /// Host-only broadcast.  Caller (PDFViewerScreen) must apply the 50 ms
  /// debounce before invoking this.
  void broadcastScroll(int page, double offsetY) {
    if (_currentRole != 'host') return;
    _syncService.broadcastScroll(page, offsetY);
  }

  /// Viewer free-scroll persistence (debounced inside [SyncService]).
  void broadcastViewerScroll(int page, double offsetY) {
    if (_currentRole != 'viewer') return;
    if (state.viewerState != ViewerSyncState.free) return;
    _syncService.sendViewerScroll(page, offsetY);
  }

  // --------------------------------------------------------------------------
  // Viewer sync state transitions
  // --------------------------------------------------------------------------

  /// Viewer explicitly opts back into host sync.
  /// State machine: free → synced
  void rejoinSync(String roomId) {
    _syncService.rejoinSync(roomId);
    state = state.copyWith(
      viewerState: ViewerSyncState.synced,
      bannerState: BannerState.hidden,
      clearReconnectingHost: true,
    );
  }

  /// Hides the current banner without changing the viewer sync state.
  void dismissBanner() {
    state = state.copyWith(bannerState: BannerState.hidden);
  }

  /// Clears [SyncState.joinHostPage] after the viewer has acted on the offer.
  void clearJoinHostPage() {
    state = state.copyWith(clearJoinHostPage: true);
  }

  /// Tells the server the host is opening a new session for [roomId] with
  /// [fileName].  Called by [PDFViewerScreen] after the host picks a PDF.
  void notifyRoomCreated(String roomId, String fileName) {
    _syncService.createRoom(roomId, fileName);
  }

  // --------------------------------------------------------------------------
  // App lifecycle
  // --------------------------------------------------------------------------

  /// Call from [WidgetsBindingObserver.didChangeAppLifecycleState] when
  /// [AppLifecycleState.resumed].
  void onAppResumed() {
    _syncService.onAppResumed();
  }

  // --------------------------------------------------------------------------
  // Internal event handler
  // --------------------------------------------------------------------------

  void _handleEvent(SyncEvent event) {
    switch (event) {
      case RoomJoinedEvent(:final hostPage):
        // Connection is fully established.
        // If the host is already past page 1, store it so PDFViewerScreen
        // can offer to jump there once the PDF loads.
        state = state.copyWith(
          isConnected: true,
          joinHostPage: hostPage > 1 ? hostPage : null,
        );

      case ParticipantsEvent(:final count):
        state = state.copyWith(participantCount: count);

      case HostDisconnectedEvent(:final lastPage, :final lastOffsetY):
        // State machine: synced → free
        state = state.copyWith(
          viewerState: ViewerSyncState.free,
          bannerState: BannerState.hostDisconnected,
          lastHostPage: lastPage,
          lastHostOffset: lastOffsetY,
        );

      case HostReconnectedEvent(:final page, :final offsetY, :final hostName):
        // Viewer stays free until REJOIN_SYNC.  Show reconnect banner.
        state = state.copyWith(
          bannerState: BannerState.hostReconnected,
          reconnectingHost: HostInfo(name: hostName, page: page, offsetY: offsetY),
        );

      case RoomClosedEvent():
        // State machine: any → closed
        state = state.copyWith(bannerState: BannerState.sessionClosed);

      case RejoinContextEvent():
        // After reconnect the viewer was previously disconnected.
        // State machine: disconnected → free, then let PDFViewerScreen
        // restore position.  (PDFViewerScreen listens to the raw stream.)
        state = state.copyWith(viewerState: ViewerSyncState.free);

      case SyncScrollEvent():
        // Do NOT store scroll events in state — forward them via the stream
        // directly to PDFViewerScreen.  State is unaffected.
        break;

      case PdfReadyEvent():
        // Forwarded via the raw event stream to PDFViewerScreen.
        // State is unaffected here.
        break;

      case ErrorEvent(:final code, :final message):
        if (code == 'ROOM_CLOSED') {
          // Room was closed while the user was navigating in — treat as
          // SESSION_CLOSED so the UI shows the session-ended banner/dialog.
          state = state.copyWith(bannerState: BannerState.sessionClosed);
        } else {
          // ignore: avoid_print
          print('[SyncService] WS error $code: $message');
        }

      // Dart sealed-class exhaustiveness: no default needed if every
      // subclass is handled.
    }
  }
}
