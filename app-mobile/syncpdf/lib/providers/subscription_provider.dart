import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';

part 'subscription_provider.g.dart';

// ---------------------------------------------------------------------------
// Subscription status provider
// ---------------------------------------------------------------------------

@riverpod
Future<Subscription> subscription(Ref ref) =>
    SubscriptionService().getStatus();

// ---------------------------------------------------------------------------
// Computed convenience provider
// ---------------------------------------------------------------------------

/// True when the user has an active trial or paid subscription.
/// Returns false if the subscription hasn't loaded yet or has no value.
@riverpod
bool isSubscriptionActive(Ref ref) {
  final sub = ref.watch(subscriptionProvider).valueOrNull;
  return sub?.isActive ?? false;
}
