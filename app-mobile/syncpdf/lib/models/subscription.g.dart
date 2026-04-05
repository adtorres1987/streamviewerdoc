// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      status: json['status'] as String,
      trialDays: (json['trial_days'] as num).toInt(),
      trialEndsAt: DateTime.parse(json['trial_ends_at'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'trial_days': instance.trialDays,
      'trial_ends_at': instance.trialEndsAt.toIso8601String(),
      'current_period_end': instance.currentPeriodEnd?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
    };
