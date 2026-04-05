import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_settings.freezed.dart';
part 'global_settings.g.dart';

@freezed
class GlobalSettings with _$GlobalSettings {
  const factory GlobalSettings({
    @JsonKey(name: 'host_reconnect_timeout_min') required int hostReconnectTimeoutMin,
    @JsonKey(name: 'scroll_debounce_ms') required int scrollDebounceMs,
    @JsonKey(name: 'default_trial_days') required int defaultTrialDays,
  }) = _GlobalSettings;

  factory GlobalSettings.fromJson(Map<String, dynamic> json) =>
      _$GlobalSettingsFromJson(json);
}
