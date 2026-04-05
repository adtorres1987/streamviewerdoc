import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

@freezed
class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String name,
    @JsonKey(name: 'price_usd') required double priceUsd,
    @JsonKey(name: 'duration_days') required int durationDays,
    @JsonKey(name: 'stripe_price_id') required String stripePriceId,
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}
