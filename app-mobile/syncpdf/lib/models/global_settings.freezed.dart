// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GlobalSettings _$GlobalSettingsFromJson(Map<String, dynamic> json) {
  return _GlobalSettings.fromJson(json);
}

/// @nodoc
mixin _$GlobalSettings {
  @JsonKey(name: 'host_reconnect_timeout_min')
  int get hostReconnectTimeoutMin => throw _privateConstructorUsedError;
  @JsonKey(name: 'scroll_debounce_ms')
  int get scrollDebounceMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_trial_days')
  int get defaultTrialDays => throw _privateConstructorUsedError;

  /// Serializes this GlobalSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GlobalSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GlobalSettingsCopyWith<GlobalSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GlobalSettingsCopyWith<$Res> {
  factory $GlobalSettingsCopyWith(
          GlobalSettings value, $Res Function(GlobalSettings) then) =
      _$GlobalSettingsCopyWithImpl<$Res, GlobalSettings>;
  @useResult
  $Res call(
      {@JsonKey(name: 'host_reconnect_timeout_min') int hostReconnectTimeoutMin,
      @JsonKey(name: 'scroll_debounce_ms') int scrollDebounceMs,
      @JsonKey(name: 'default_trial_days') int defaultTrialDays});
}

/// @nodoc
class _$GlobalSettingsCopyWithImpl<$Res, $Val extends GlobalSettings>
    implements $GlobalSettingsCopyWith<$Res> {
  _$GlobalSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GlobalSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostReconnectTimeoutMin = null,
    Object? scrollDebounceMs = null,
    Object? defaultTrialDays = null,
  }) {
    return _then(_value.copyWith(
      hostReconnectTimeoutMin: null == hostReconnectTimeoutMin
          ? _value.hostReconnectTimeoutMin
          : hostReconnectTimeoutMin // ignore: cast_nullable_to_non_nullable
              as int,
      scrollDebounceMs: null == scrollDebounceMs
          ? _value.scrollDebounceMs
          : scrollDebounceMs // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTrialDays: null == defaultTrialDays
          ? _value.defaultTrialDays
          : defaultTrialDays // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GlobalSettingsImplCopyWith<$Res>
    implements $GlobalSettingsCopyWith<$Res> {
  factory _$$GlobalSettingsImplCopyWith(_$GlobalSettingsImpl value,
          $Res Function(_$GlobalSettingsImpl) then) =
      __$$GlobalSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'host_reconnect_timeout_min') int hostReconnectTimeoutMin,
      @JsonKey(name: 'scroll_debounce_ms') int scrollDebounceMs,
      @JsonKey(name: 'default_trial_days') int defaultTrialDays});
}

/// @nodoc
class __$$GlobalSettingsImplCopyWithImpl<$Res>
    extends _$GlobalSettingsCopyWithImpl<$Res, _$GlobalSettingsImpl>
    implements _$$GlobalSettingsImplCopyWith<$Res> {
  __$$GlobalSettingsImplCopyWithImpl(
      _$GlobalSettingsImpl _value, $Res Function(_$GlobalSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of GlobalSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostReconnectTimeoutMin = null,
    Object? scrollDebounceMs = null,
    Object? defaultTrialDays = null,
  }) {
    return _then(_$GlobalSettingsImpl(
      hostReconnectTimeoutMin: null == hostReconnectTimeoutMin
          ? _value.hostReconnectTimeoutMin
          : hostReconnectTimeoutMin // ignore: cast_nullable_to_non_nullable
              as int,
      scrollDebounceMs: null == scrollDebounceMs
          ? _value.scrollDebounceMs
          : scrollDebounceMs // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTrialDays: null == defaultTrialDays
          ? _value.defaultTrialDays
          : defaultTrialDays // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GlobalSettingsImpl implements _GlobalSettings {
  const _$GlobalSettingsImpl(
      {@JsonKey(name: 'host_reconnect_timeout_min')
      required this.hostReconnectTimeoutMin,
      @JsonKey(name: 'scroll_debounce_ms') required this.scrollDebounceMs,
      @JsonKey(name: 'default_trial_days') required this.defaultTrialDays});

  factory _$GlobalSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GlobalSettingsImplFromJson(json);

  @override
  @JsonKey(name: 'host_reconnect_timeout_min')
  final int hostReconnectTimeoutMin;
  @override
  @JsonKey(name: 'scroll_debounce_ms')
  final int scrollDebounceMs;
  @override
  @JsonKey(name: 'default_trial_days')
  final int defaultTrialDays;

  @override
  String toString() {
    return 'GlobalSettings(hostReconnectTimeoutMin: $hostReconnectTimeoutMin, scrollDebounceMs: $scrollDebounceMs, defaultTrialDays: $defaultTrialDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSettingsImpl &&
            (identical(
                    other.hostReconnectTimeoutMin, hostReconnectTimeoutMin) ||
                other.hostReconnectTimeoutMin == hostReconnectTimeoutMin) &&
            (identical(other.scrollDebounceMs, scrollDebounceMs) ||
                other.scrollDebounceMs == scrollDebounceMs) &&
            (identical(other.defaultTrialDays, defaultTrialDays) ||
                other.defaultTrialDays == defaultTrialDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, hostReconnectTimeoutMin, scrollDebounceMs, defaultTrialDays);

  /// Create a copy of GlobalSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalSettingsImplCopyWith<_$GlobalSettingsImpl> get copyWith =>
      __$$GlobalSettingsImplCopyWithImpl<_$GlobalSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GlobalSettingsImplToJson(
      this,
    );
  }
}

abstract class _GlobalSettings implements GlobalSettings {
  const factory _GlobalSettings(
      {@JsonKey(name: 'host_reconnect_timeout_min')
      required final int hostReconnectTimeoutMin,
      @JsonKey(name: 'scroll_debounce_ms') required final int scrollDebounceMs,
      @JsonKey(name: 'default_trial_days')
      required final int defaultTrialDays}) = _$GlobalSettingsImpl;

  factory _GlobalSettings.fromJson(Map<String, dynamic> json) =
      _$GlobalSettingsImpl.fromJson;

  @override
  @JsonKey(name: 'host_reconnect_timeout_min')
  int get hostReconnectTimeoutMin;
  @override
  @JsonKey(name: 'scroll_debounce_ms')
  int get scrollDebounceMs;
  @override
  @JsonKey(name: 'default_trial_days')
  int get defaultTrialDays;

  /// Create a copy of GlobalSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalSettingsImplCopyWith<_$GlobalSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
