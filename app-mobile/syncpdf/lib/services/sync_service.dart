import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants.dart';
import '../models/sync_event.dart';

/// Low-level WebSocket client for the SyncPDF real-time protocol.
///
/// Responsibilities:
///   - Connect / reconnect with exponential backoff
///   - PING/PONG heartbeat every [AppConstants.heartbeatIntervalSec] seconds
///   - Emit typed [SyncEvent]s on the [events] broadcast stream
///   - Send JOIN_ROOM, SCROLL, VIEWER_SCROLL, REJOIN_SYNC messages
///
/// Lifecycle: create once per room session, call [disconnect] in dispose().
class SyncService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  String? _currentRoomId;
  String? _jwt;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _viewerScrollDebounce;

  int _reconnectAttempts = 0;
  bool _disposed = false;

  final _eventController = StreamController<SyncEvent>.broadcast();

  /// Broadcast stream of all parsed server events.  Listeners in
  /// [SyncNotifier] and [PDFViewerScreen] subscribe here.
  Stream<SyncEvent> get events => _eventController.stream;

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Begin connecting using [jwt].  Safe to call again after a disconnect.
  void connect(String jwt) {
    _jwt = jwt;
    _disposed = false;
    _doConnect();
  }

  /// Join [roomId] on the server.  Stores [roomId] so it is auto-rejoined
  /// after reconnects.
  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    _send({'type': 'JOIN_ROOM', 'roomId': roomId});
  }

  /// Tell the server the host is creating a new session for [roomId].
  void createRoom(String roomId, String fileName) {
    _currentRoomId = roomId;
    _send({'type': 'CREATE_ROOM', 'roomId': roomId, 'fileName': fileName});
  }

  /// Host-only — caller must apply 50 ms debounce before calling.
  void broadcastScroll(int page, double offsetY) {
    if (_currentRoomId == null) return;
    _send({
      'type': 'SCROLL',
      'roomId': _currentRoomId,
      'page': page,
      'offsetY': offsetY,
    });
  }

  /// Viewer free-scroll persistence — debounced internally to
  /// [AppConstants.viewerPersistDebounceMs] (5 000 ms).
  void sendViewerScroll(int page, double offsetY) {
    if (_currentRoomId == null) return;
    final roomId = _currentRoomId;
    _viewerScrollDebounce?.cancel();
    _viewerScrollDebounce = Timer(
      const Duration(milliseconds: AppConstants.viewerPersistDebounceMs),
      () => _send({
        'type': 'VIEWER_SCROLL',
        'roomId': roomId,
        'page': page,
        'offsetY': offsetY,
      }),
    );
  }

  /// Viewer requests to re-sync with the host after being in free mode.
  void rejoinSync(String roomId) {
    _send({'type': 'REJOIN_SYNC', 'roomId': roomId});
  }

  /// Call when the app returns to foreground to ensure the connection is live.
  /// Resets the backoff counter so reconnect is immediate.
  void onAppResumed() {
    if (_currentRoomId != null) {
      _reconnectAttempts = 0;
      _doConnect();
    }
  }

  /// Permanently tears down the service.  Call this in dispose().
  void disconnect() {
    _disposed = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _viewerScrollDebounce?.cancel();
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _eventController.close();
  }

  // --------------------------------------------------------------------------
  // Internal — connection management
  // --------------------------------------------------------------------------

  void _doConnect() {
    // Cancel the old subscription BEFORE closing the channel so that
    // _onDisconnected does not fire for an intentional close and trigger
    // a spurious reconnect cycle.
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;

    final uri = Uri.parse('${AppConstants.wsUrl}?token=$_jwt');
    _channel = WebSocketChannel.connect(uri);

    _channelSub = _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
      cancelOnError: true,
    );

    _reconnectAttempts = 0;
    _startHeartbeat();

    // Auto-rejoin a room if we were already in one (reconnect scenario).
    if (_currentRoomId != null) {
      joinRoom(_currentRoomId!);
    }
  }

  void _onDisconnected() {
    _stopHeartbeat();
    _channel = null;
    _channelSub = null;

    if (!_disposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    final delays = AppConstants.reconnectBackoffSeconds;
    final index = _reconnectAttempts.clamp(0, delays.length - 1);
    final delaySec = delays[index];
    if (_reconnectAttempts < delays.length - 1) _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (!_disposed) _doConnect();
    });
  }

  // --------------------------------------------------------------------------
  // Internal — message parsing
  // --------------------------------------------------------------------------

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // PONG is a heartbeat reply — no need to propagate to UI.
      if (map['type'] == 'PONG') return;
      final event = SyncEvent.fromJson(map);
      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
    } catch (_) {
      // Malformed message — ignore silently.
    }
  }

  // --------------------------------------------------------------------------
  // Internal — heartbeat
  // --------------------------------------------------------------------------

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.heartbeatIntervalSec),
      (_) => _send({'type': 'PING'}),
    );
  }

  void _stopHeartbeat() => _heartbeatTimer?.cancel();

  // --------------------------------------------------------------------------
  // Internal — send helper
  // --------------------------------------------------------------------------

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {
      // Channel may be closed during a reconnect race — safe to swallow.
    }
  }
}
