import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';

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

  @override
  void dispose() {
    _linkSub?.cancel();
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
