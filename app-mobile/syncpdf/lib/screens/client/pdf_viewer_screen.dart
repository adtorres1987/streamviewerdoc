import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants.dart';
import '../../models/sync_event.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/page_indicator.dart';
import '../../widgets/room_overlay.dart';
import '../../widgets/sync_banner.dart';

/// Full-screen PDF viewer with real-time WebSocket synchronization.
///
/// Roles:
///   - host    → picks a local PDF, broadcasts scroll events (50 ms debounce)
///   - viewer  → receives scroll events when synced; scrolls freely when free
///
/// Scroll echo prevention:
///   [_suppressNextScroll] is set to `true` before every programmatic scroll.
///   The next scroll event from [SfPdfViewer] is then ignored to prevent
///   echoing the position back to the server.
class PDFViewerScreen extends ConsumerStatefulWidget {
  const PDFViewerScreen({
    super.key,
    required this.roomId,
    required this.role,
  });

  final String roomId;

  /// Either `'host'` or `'viewer'`.
  final String role;

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen>
    with WidgetsBindingObserver {

  // --------------------------------------------------------------------------
  // PDF viewer
  // --------------------------------------------------------------------------

  final PdfViewerController _pdfController = PdfViewerController();

  /// Local file path to the selected PDF.  Null until the host picks a file
  /// (for host) or until the server sends the PDF URL (viewer — future work).
  String? _pdfPath;

  // --------------------------------------------------------------------------
  // Scroll echo prevention
  // --------------------------------------------------------------------------

  /// When `true`, the next scroll/page-change event from [SfPdfViewer] is
  /// suppressed.  Set before any programmatic scroll so the viewer does not
  /// broadcast the position it just received from the host.
  bool _suppressNextScroll = false;

  // --------------------------------------------------------------------------
  // WebSocket subscription & timers
  // --------------------------------------------------------------------------

  StreamSubscription<SyncEvent>? _syncSub;

  /// 50 ms debounce timer — host only.
  Timer? _hostScrollDebounce;

  // --------------------------------------------------------------------------
  // UI state
  // --------------------------------------------------------------------------

  bool _showOverlay = false;

  /// Room code displayed in the overlay — populated from [RoomJoinedEvent].
  String _roomCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer init so ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSync();
      if (widget.role == 'host') _pickPdf();
    });
  }

  // --------------------------------------------------------------------------
  // Init
  // --------------------------------------------------------------------------

  Future<void> _initSync() async {
    await ref.read(syncNotifierProvider.notifier).connect(
          widget.roomId,
          widget.role,
        );

    // Subscribe to raw events for position-changing reactions.
    _syncSub = ref
        .read(syncNotifierProvider.notifier)
        .eventStream
        .listen(_onSyncEvent);
  }

  // --------------------------------------------------------------------------
  // File picker (host only)
  // --------------------------------------------------------------------------

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || !mounted) return;

    final path = result.files.single.path;
    if (path == null) return;

    final fileName = result.files.single.name;

    setState(() => _pdfPath = path);

    // Notify the server so it registers the PDF name for this session.
    ref
        .read(syncNotifierProvider.notifier)
        .notifyRoomCreated(widget.roomId, fileName);
  }

  // --------------------------------------------------------------------------
  // WebSocket event handler
  // --------------------------------------------------------------------------

  void _onSyncEvent(SyncEvent event) {
    switch (event) {
      case RoomJoinedEvent(:final code):
        // Capture the room code for the overlay.
        if (mounted) setState(() => _roomCode = code);

      case SyncScrollEvent(:final page):
        // Viewer-only: apply the host's scroll position.
        // offsetY is received by SyncScrollEvent but SfPdfViewer does not
        // expose a public scrollTo(offset) for live programmatic use.
        // The page jump is the primary sync signal; sub-page offset sync
        // is a future improvement via initialScrollOffset on rebuild.
        if (widget.role != 'viewer') break;
        if (!mounted) break;
        _suppressNextScroll = true;
        _pdfController.jumpToPage(page);

      case RejoinContextEvent(:final yourLastPage):
        // Reconnect context: restore the viewer's last position.
        if (!mounted) break;
        _suppressNextScroll = true;
        _pdfController.jumpToPage(yourLastPage);

      case RoomClosedEvent():
        _showSessionClosedDialog();

      default:
        // All other events (HOST_DISCONNECTED, HOST_RECONNECTED, PARTICIPANTS)
        // are handled by SyncNotifier and reflected in SyncState — the banner
        // builder below reacts to them automatically.
        break;
    }
  }

  // --------------------------------------------------------------------------
  // Host scroll handler (50 ms debounce)
  // --------------------------------------------------------------------------

  void _onHostScrolled() {
    if (_suppressNextScroll) {
      _suppressNextScroll = false;
      return;
    }
    _hostScrollDebounce?.cancel();
    _hostScrollDebounce = Timer(
      const Duration(milliseconds: AppConstants.scrollDebounceMsHost),
      () {
        if (!mounted) return;
        final page = _pdfController.pageNumber;
        final offsetY = _pdfController.scrollOffset.dy;
        ref.read(syncNotifierProvider.notifier).broadcastScroll(page, offsetY);
      },
    );
  }

  // --------------------------------------------------------------------------
  // Viewer free-scroll handler
  // --------------------------------------------------------------------------

  void _onViewerScrolled() {
    if (_suppressNextScroll) {
      _suppressNextScroll = false;
      return;
    }
    final syncState = ref.read(syncNotifierProvider).viewerState;
    if (syncState == ViewerSyncState.free) {
      final page = _pdfController.pageNumber;
      final offsetY = _pdfController.scrollOffset.dy;
      ref
          .read(syncNotifierProvider.notifier)
          .broadcastViewerScroll(page, offsetY);
    }
  }

  // --------------------------------------------------------------------------
  // Session closed dialog
  // --------------------------------------------------------------------------

  void _showSessionClosedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sesion terminada'),
        content: const Text(
          'El host no reconecto a tiempo. La sesion fue cerrada.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // App lifecycle
  // --------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncNotifierProvider.notifier).onAppResumed();
    }
  }

  // --------------------------------------------------------------------------
  // Dispose
  // --------------------------------------------------------------------------

  @override
  void dispose() {
    _syncSub?.cancel();
    _hostScrollDebounce?.cancel();
    // SyncNotifier.disconnect() is called via ref.onDispose in the provider,
    // but we also call it explicitly here for clarity and immediacy.
    ref.read(syncNotifierProvider.notifier).disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala · ${widget.roomId.substring(0, 8)}'),
        actions: [
          // Page indicator — only meaningful when a PDF is loaded.
          if (_pdfPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: PageIndicator(controller: _pdfController),
            ),
          // Participant count chip.
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              avatar: const Icon(Icons.people_outline, size: 16),
              label: Text('${syncState.participantCount}'),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Overlay toggle.
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info de sala',
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ------------------------------------------------------------------
          // Main content: PDF viewer or placeholder
          // ------------------------------------------------------------------
          if (_pdfPath != null)
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // React on scroll-end to avoid firing too aggressively.
                if (notification is ScrollEndNotification) {
                  if (widget.role == 'host') {
                    _onHostScrolled();
                  } else {
                    _onViewerScrolled();
                  }
                }
                return false; // Let the notification continue to bubble.
              },
              child: SfPdfViewer.file(
                File(_pdfPath!),
                controller: _pdfController,
                onPageChanged: (details) {
                  if (widget.role == 'host') {
                    _onHostScrolled();
                  } else {
                    _onViewerScrolled();
                  }
                  // Trigger a rebuild so PageIndicator updates.
                  if (mounted) setState(() {});
                },
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: widget.role == 'host'
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file,
                              size: 64, color: Color(0xFF4F46E5)),
                          const SizedBox(height: 20),
                          Text(
                            'Selecciona un PDF para comenzar',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Seleccionar PDF'),
                            onPressed: _pickPdf,
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Esperando al host...'),
                        ],
                      ),
              ),
            ),

          // ------------------------------------------------------------------
          // Room overlay (top-right, toggle with AppBar icon)
          // ------------------------------------------------------------------
          if (_showOverlay && _roomCode.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: RoomOverlay(
                roomCode: _roomCode,
                participantCount: syncState.participantCount,
                onClose: () => setState(() => _showOverlay = false),
              ),
            ),

          // ------------------------------------------------------------------
          // Status banners (bottom of screen)
          // ------------------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBanner(syncState),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Banner factory
  // --------------------------------------------------------------------------

  Widget _buildBanner(SyncState syncState) {
    return switch (syncState.bannerState) {
      BannerState.hidden => const SizedBox.shrink(),

      BannerState.hostDisconnected => HostDisconnectedBanner(
          lastPage: syncState.lastHostPage,
        ),

      BannerState.hostReconnected => HostReconnectedBanner(
          hostName: syncState.reconnectingHost?.name ?? 'El host',
          onAccept: () =>
              ref.read(syncNotifierProvider.notifier).rejoinSync(widget.roomId),
          onDecline: () =>
              ref.read(syncNotifierProvider.notifier).dismissBanner(),
        ),

      BannerState.sessionClosed => SessionClosedBanner(
          onClose: () => context.pop(),
        ),
    };
  }
}

