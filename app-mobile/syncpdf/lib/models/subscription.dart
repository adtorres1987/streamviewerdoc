import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    /// One of: 'trial' | 'active' | 'expired' | 'cancelled'
    required String status,
    @JsonKey(name: 'trial_days') required int trialDays,
    @JsonKey(name: 'trial_ends_at') required DateTime trialEndsAt,
    @JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

/// Extension for derived business logic — kept out of freezed to stay pure.
extension SubscriptionX on Subscription {
  bool get isActive {
    if (status == 'trial') return trialEndsAt.isAfter(DateTime.now());
    if (status == 'active') {
      return currentPeriodEnd?.isAfter(DateTime.now()) ?? false;
    }
    return false;
  }

  int get daysRemaining {
    final end = status == 'trial' ? trialEndsAt : currentPeriodEnd;
    if (end == null) return 0;
    final diff = end.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// True when Stripe set cancel_at_period_end — access continues until
  /// [currentPeriodEnd] but no new billing cycle will start.
  bool get isCancellingAtPeriodEnd =>
      status == 'cancelled' && currentPeriodEnd != null && currentPeriodEnd!.isAfter(DateTime.now());
}
