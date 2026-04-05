// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GlobalSettingsImpl _$$GlobalSettingsImplFromJson(Map<String, dynamic> json) =>
    _$GlobalSettingsImpl(
      hostReconnectTimeoutMin:
          (json['host_reconnect_timeout_min'] as num).toInt(),
      scrollDebounceMs: (json['scroll_debounce_ms'] as num).toInt(),
      defaultTrialDays: (json['default_trial_days'] as num).toInt(),
    );

Map<String, dynamic> _$$GlobalSettingsImplToJson(
        _$GlobalSettingsImpl instance) =>
    <String, dynamic>{
      'host_reconnect_timeout_min': instance.hostReconnectTimeoutMin,
      'scroll_debounce_ms': instance.scrollDebounceMs,
      'default_trial_days': instance.defaultTrialDays,
    };
