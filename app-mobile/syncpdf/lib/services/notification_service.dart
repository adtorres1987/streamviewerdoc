// lib/services/notification_service.dart
//
// NotificationService — Singleton that wraps Firebase Cloud Messaging (FCM)
// and flutter_local_notifications into a single, initialisation-ordered surface.
//
// Lifecycle:
//   1. main.dart calls `await NotificationService().initialize()` after
//      `Firebase.initializeApp()`.
//   2. The service requests permissions, sets up the Android channel, wires
//      foreground/tap handlers, and configures iOS foreground presentation.
//   3. On foreground messages the OS does NOT show a banner — we do it ourselves
//      via flutter_local_notifications (see [showLocalNotification]).
//   4. Background / terminated messages are handled transparently by the OS
//      using the top-level handler registered in main.dart.
//
// Testing from Firebase Console:
//   Firebase Console → Engage → Messaging → "Send your first message"
//   → Set a notification title/body → Send test message → enter the FCM token
//   (printed to console during development via `getFcmToken()`).
//   To test data-only messages (which drive in-app navigation), use the
//   Firebase Admin SDK or REST API with `data` payload and no `notification`
//   field so the foreground handler fires instead of the OS.
//
// Notification tap navigation is driven by the `route` key in the FCM
// `data` map. Supported values:
//   data['route'] = '/home'              → navigates to HomeScreen
//   data['route'] = '/room/<roomId>'     → navigates to PDFViewerScreen
//   data['route'] = '/groups/<groupId>'  → navigates to GroupScreen
// Add more entries here as the backend begins sending richer push events.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ---------------------------------------------------------------------------
// Android notification channel
// ---------------------------------------------------------------------------

const _kChannelId = 'syncpdf_channel';
const _kChannelName = 'SyncPDF';
const _kChannelDescription = 'Real-time session and invitation alerts.';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: _kChannelDescription,
  importance: Importance.high,
);

// ---------------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------------

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Called by the navigation handler set up in app.dart.
  // Receives the `data` map from the tapped FCM message.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Must be called after [Firebase.initializeApp()].
  /// Sets up channels, permissions, and all message handlers.
  Future<void> initialize() async {
    await _createAndroidChannel();
    await _requestPermissions();
    await _configureForegroundiOS();
    _setupForegroundHandler();
    _setupInteractionHandler();
  }

  /// Returns the FCM registration token for this device.
  /// Log this during development to send test messages from the console.
  Future<String?> getFcmToken() async {
    final token = await _fcm.getToken();
    // ignore: avoid_print
    assert(() {
      // ignore: avoid_print
      print('[NotificationService] FCM token: $token');
      return true;
    }());
    return token;
  }

  /// Subscribes to FCM token refresh events so the backend can be notified
  /// when the device token rotates.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _createAndroidChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermissions() async {
    // iOS / macOS — request notification permission explicitly.
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android 13+ (API 33) requires runtime permission. The firebase_messaging
    // package surfaces this through requestPermission() as well.

    // Initialise the local notifications plugin (needed for foreground display).
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// On iOS, FCM suppresses foreground banners by default.
  /// This restores them so the user sees the notification while using the app.
  Future<void> _configureForegroundiOS() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Listens for FCM messages that arrive while the app is in the foreground.
  /// The OS will NOT display a banner — we show a local notification instead.
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });
  }

  /// Handles the case where the user taps a notification that was delivered
  /// while the app was in the background or terminated.
  ///
  /// - [FirebaseMessaging.onMessageOpenedApp] fires when the app was in the
  ///   background and the user taps the system notification.
  /// - [FirebaseMessaging.instance.getInitialMessage()] returns a message when
  ///   the app was fully terminated and launched via a notification tap.
  void _setupInteractionHandler() {
    // Background → foreground tap.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleTap(message.data);
    });

    // Terminated → opened tap (async; must be polled after init).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleTap(message.data);
      }
    });
  }

  /// Displays a local notification banner for a message that arrived in the
  /// foreground. The notification's payload is the JSON-encoded data map so
  /// the tap handler can extract the route.
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return; // Data-only message — no visual banner.

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      // Use a stable id derived from the message so rapid bursts don't stack
      // unboundedly. Overflow wraps to a positive int safely.
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      // Pass the route string as the payload so the tap handler can navigate.
      payload: message.data['route'] as String?,
    );
  }

  // Tap on a local notification (foreground message).
  void _onLocalNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      _handleTap({'route': route});
    }
  }

  // Central navigation dispatch.  Callers set [onNotificationTap] from
  // app.dart after the router is ready.
  void _handleTap(Map<String, dynamic> data) {
    onNotificationTap?.call(data);
  }
}
