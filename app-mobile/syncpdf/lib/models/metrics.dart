import 'package:freezed_annotation/freezed_annotation.dart';

part 'metrics.freezed.dart';
part 'metrics.g.dart';

@freezed
class Metrics with _$Metrics {
  const factory Metrics({
    @JsonKey(name: 'total_clients') required int totalClients,
    @JsonKey(name: 'active_subscriptions') required int activeSubscriptions,
    @JsonKey(name: 'trial_subscriptions') required int trialSubscriptions,
    @JsonKey(name: 'expired_subscriptions') required int expiredSubscriptions,
    @JsonKey(name: 'active_rooms') required int activeRooms,
  }) = _Metrics;

  factory Metrics.fromJson(Map<String, dynamic> json) =>
      _$MetricsFromJson(json);
}
