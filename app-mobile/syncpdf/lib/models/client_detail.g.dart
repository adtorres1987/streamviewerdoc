// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClientDetailImpl _$$ClientDetailImplFromJson(Map<String, dynamic> json) =>
    _$ClientDetailImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      status: json['status'] as String,
      subscriptionStatus: json['subscription_status'] as String?,
      trialEndsAt: json['trial_ends_at'] == null
          ? null
          : DateTime.parse(json['trial_ends_at'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ClientDetailImplToJson(_$ClientDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'status': instance.status,
      'subscription_status': instance.subscriptionStatus,
      'trial_ends_at': instance.trialEndsAt?.toIso8601String(),
      'current_period_end': instance.currentPeriodEnd?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
