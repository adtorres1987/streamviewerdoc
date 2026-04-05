// lib/main.dart
//
// SETUP REQUIRED — Firebase configuration files:
//   Android: place `google-services.json` in `android/app/`
//   iOS:     place `GoogleService-Info.plist` in `ios/Runner/` (via Xcode)
//
// Obtain both files from Firebase Console → Project settings → Your apps.
// Without these files `Firebase.initializeApp()` will throw at runtime.
// The files are intentionally excluded from version control — add them to
// `.gitignore` if they are not already listed there.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'core/constants.dart';
import 'services/notification_service.dart';

// ---------------------------------------------------------------------------
// Background message handler — MUST be a top-level function.
//
// Firebase invokes this in an isolate when a data-only or notification message
// arrives while the app is in the background or terminated. It must be
// annotated @pragma('vm:entry-point') so the Dart compiler does not tree-shake
// it, and it must call `Firebase.initializeApp()` because the isolate has no
// shared state with the main isolate.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background and terminated-state notification banners are displayed
  // automatically by the OS using the FCM payload — no extra work needed here.
  // Add backend acknowledgement logic here if required in the future.
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be initialised before any other Firebase call.
  await Firebase.initializeApp();

  // Register the background message handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // 2. Notification service sets up channels, permissions, and handlers.
  //    Must run after Firebase.initializeApp().
  await NotificationService().initialize();

  // 3. Stripe must be initialised before the widget tree is built.
  //    The key comes from --dart-define=STRIPE_PUBLISHABLE_KEY=pk_...
  //    Skip init in dev if no key is provided (payments will fail gracefully).
  if (AppConstants.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: SyncPDFApp()));
}
