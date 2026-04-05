import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

/// Returns `true` if the current user has an active subscription.
/// If inactive, pushes `/paywall` and returns `false`.
///
/// Call this at the start of any action that requires an active subscription
/// (e.g. creating a room or starting a session).
Future<bool> checkRoomAccess(WidgetRef ref, BuildContext context) async {
  final sub = ref.read(subscriptionProvider).valueOrNull;
  if (sub == null || !sub.isActive) {
    context.push('/paywall');
    return false;
  }
  return true;
}
