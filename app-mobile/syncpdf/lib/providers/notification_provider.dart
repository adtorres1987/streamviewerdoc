// lib/providers/notification_provider.dart
//
// Exposes the device's FCM registration token via Riverpod so that any screen
// or service can read it and forward it to the backend for targeted pushes.
//
// Usage:
//   final asyncToken = ref.watch(fcmTokenProvider);
//   asyncToken.whenData((token) => myApiService.updateFcmToken(token));

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/notification_service.dart';

part 'notification_provider.g.dart';

/// Resolves to the FCM registration token for the current device.
/// Returns null when Firebase Messaging is unavailable (e.g. simulator without
/// Google Play Services) or before the token is issued.
@riverpod
Future<String?> fcmToken(Ref ref) async {
  return NotificationService().getFcmToken();
}
