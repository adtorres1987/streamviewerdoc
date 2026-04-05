import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_detail.freezed.dart';
part 'client_detail.g.dart';

@freezed
class ClientDetail with _$ClientDetail {
  const factory ClientDetail({
    required String id,
    required String email,
    /// Backend returns `full_name` (snake_case).
    @JsonKey(name: 'full_name') required String fullName,
    /// One of: 'pending' | 'active' | 'suspended'
    required String status,
    /// One of: 'trial' | 'active' | 'expired' | 'cancelled' — nullable if no subscription.
    @JsonKey(name: 'subscription_status') String? subscriptionStatus,
    @JsonKey(name: 'trial_ends_at') DateTime? trialEndsAt,
    @JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ClientDetail;

  factory ClientDetail.fromJson(Map<String, dynamic> json) =>
      _$ClientDetailFromJson(json);
}
