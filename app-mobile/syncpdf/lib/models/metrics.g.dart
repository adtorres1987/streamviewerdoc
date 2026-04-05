// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MetricsImpl _$$MetricsImplFromJson(Map<String, dynamic> json) =>
    _$MetricsImpl(
      totalClients: (json['total_clients'] as num).toInt(),
      activeSubscriptions: (json['active_subscriptions'] as num).toInt(),
      trialSubscriptions: (json['trial_subscriptions'] as num).toInt(),
      expiredSubscriptions: (json['expired_subscriptions'] as num).toInt(),
      activeRooms: (json['active_rooms'] as num).toInt(),
    );

Map<String, dynamic> _$$MetricsImplToJson(_$MetricsImpl instance) =>
    <String, dynamic>{
      'total_clients': instance.totalClients,
      'active_subscriptions': instance.activeSubscriptions,
      'trial_subscriptions': instance.trialSubscriptions,
      'expired_subscriptions': instance.expiredSubscriptions,
      'active_rooms': instance.activeRooms,
    };
