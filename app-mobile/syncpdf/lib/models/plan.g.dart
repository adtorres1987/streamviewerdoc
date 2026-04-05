// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanImpl _$$PlanImplFromJson(Map<String, dynamic> json) => _$PlanImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      priceUsd: (json['price_usd'] as num).toDouble(),
      durationDays: (json['duration_days'] as num).toInt(),
      stripePriceId: json['stripe_price_id'] as String,
    );

Map<String, dynamic> _$$PlanImplToJson(_$PlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_usd': instance.priceUsd,
      'duration_days': instance.durationDays,
      'stripe_price_id': instance.stripePriceId,
    };
