import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';

class SyncPDFApp extends ConsumerStatefulWidget {
  const SyncPDFApp({super.key});

  @override
  ConsumerState<SyncPDFApp> createState() => _SyncPDFAppState();
}

class _SyncPDFAppState extends ConsumerState<SyncPDFApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    _initNotificationTapHandler();
  }

  Future<void> _initDeepLinks() async {
    // Handle link when app was launched from a closed state.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleUri(initial);

    // Handle links while the app is already running.
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'syncpdf' && uri.host == 'invite') {
      final token = uri.queryParameters['token'] ?? '';
      ref.read(routerProvider).go('/invite?token=$token');
    }
  }

  // ---------------------------------------------------------------------------
  // Notification tap navigation
  //
  // [NotificationService.onNotificationTap] is set here rather than in
  // [initialize()] so we have access to the Riverpod [ref] and therefore the
  // GoRouter instance.
  //
  // Supported data['route'] patterns:
  //   '/home'             → HomeScreen
  //   '/room/<id>'        → PDFViewerScreen (defaults to viewer role)
  //   '/groups/<id>'      → GroupScreen
  //
  // Extend this list as the backend adds new notification types.
  // ---------------------------------------------------------------------------

  void _initNotificationTapHandler() {
    NotificationService().onNotificationTap = (Map<String, dynamic> data) {
      final route = data['route'] as String?;
      if (route == null || route.isEmpty) return;

      final router = ref.read(routerProvider);

      // Room notification: backend sends '/room/<roomId>'
      // GoRouter path is '/room/:id?role=viewer' — we default to viewer
      // because the server enforces the actual role.
      if (route.startsWith('/room/')) {
        final roomId = route.replaceFirst('/room/', '');
        router.go('/room/$roomId?role=viewer');
        return;
      }

      // Group notification: backend sends '/groups/<groupId>'
      if (route.startsWith('/groups/')) {
        router.go(route);
        return;
      }

      // Home and any other explicitly supported routes.
      if (route == AppRoutes.home ||
          route == AppRoutes.subscription ||
          route == AppRoutes.paywall) {
        router.go(route);
        return;
      }

      // Unknown route — fall back to home so we never leave the user stranded.
      router.go(AppRoutes.home);
    };
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    // Clear the tap handler to prevent a stale closure holding a ref.
    NotificationService().onNotificationTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
