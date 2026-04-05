// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Metrics _$MetricsFromJson(Map<String, dynamic> json) {
  return _Metrics.fromJson(json);
}

/// @nodoc
mixin _$Metrics {
  @JsonKey(name: 'total_clients')
  int get totalClients => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_subscriptions')
  int get activeSubscriptions => throw _privateConstructorUsedError;
  @JsonKey(name: 'trial_subscriptions')
  int get trialSubscriptions => throw _privateConstructorUsedError;
  @JsonKey(name: 'expired_subscriptions')
  int get expiredSubscriptions => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_rooms')
  int get activeRooms => throw _privateConstructorUsedError;

  /// Serializes this Metrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Metrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MetricsCopyWith<Metrics> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetricsCopyWith<$Res> {
  factory $MetricsCopyWith(Metrics value, $Res Function(Metrics) then) =
      _$MetricsCopyWithImpl<$Res, Metrics>;
  @useResult
  $Res call(
      {@JsonKey(name: 'total_clients') int totalClients,
      @JsonKey(name: 'active_subscriptions') int activeSubscriptions,
      @JsonKey(name: 'trial_subscriptions') int trialSubscriptions,
      @JsonKey(name: 'expired_subscriptions') int expiredSubscriptions,
      @JsonKey(name: 'active_rooms') int activeRooms});
}

/// @nodoc
class _$MetricsCopyWithImpl<$Res, $Val extends Metrics>
    implements $MetricsCopyWith<$Res> {
  _$MetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Metrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalClients = null,
    Object? activeSubscriptions = null,
    Object? trialSubscriptions = null,
    Object? expiredSubscriptions = null,
    Object? activeRooms = null,
  }) {
    return _then(_value.copyWith(
      totalClients: null == totalClients
          ? _value.totalClients
          : totalClients // ignore: cast_nullable_to_non_nullable
              as int,
      activeSubscriptions: null == activeSubscriptions
          ? _value.activeSubscriptions
          : activeSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      trialSubscriptions: null == trialSubscriptions
          ? _value.trialSubscriptions
          : trialSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      expiredSubscriptions: null == expiredSubscriptions
          ? _value.expiredSubscriptions
          : expiredSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      activeRooms: null == activeRooms
          ? _value.activeRooms
          : activeRooms // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MetricsImplCopyWith<$Res> implements $MetricsCopyWith<$Res> {
  factory _$$MetricsImplCopyWith(
          _$MetricsImpl value, $Res Function(_$MetricsImpl) then) =
      __$$MetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'total_clients') int totalClients,
      @JsonKey(name: 'active_subscriptions') int activeSubscriptions,
      @JsonKey(name: 'trial_subscriptions') int trialSubscriptions,
      @JsonKey(name: 'expired_subscriptions') int expiredSubscriptions,
      @JsonKey(name: 'active_rooms') int activeRooms});
}

/// @nodoc
class __$$MetricsImplCopyWithImpl<$Res>
    extends _$MetricsCopyWithImpl<$Res, _$MetricsImpl>
    implements _$$MetricsImplCopyWith<$Res> {
  __$$MetricsImplCopyWithImpl(
      _$MetricsImpl _value, $Res Function(_$MetricsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Metrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalClients = null,
    Object? activeSubscriptions = null,
    Object? trialSubscriptions = null,
    Object? expiredSubscriptions = null,
    Object? activeRooms = null,
  }) {
    return _then(_$MetricsImpl(
      totalClients: null == totalClients
          ? _value.totalClients
          : totalClients // ignore: cast_nullable_to_non_nullable
              as int,
      activeSubscriptions: null == activeSubscriptions
          ? _value.activeSubscriptions
          : activeSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      trialSubscriptions: null == trialSubscriptions
          ? _value.trialSubscriptions
          : trialSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      expiredSubscriptions: null == expiredSubscriptions
          ? _value.expiredSubscriptions
          : expiredSubscriptions // ignore: cast_nullable_to_non_nullable
              as int,
      activeRooms: null == activeRooms
          ? _value.activeRooms
          : activeRooms // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MetricsImpl implements _Metrics {
  const _$MetricsImpl(
      {@JsonKey(name: 'total_clients') required this.totalClients,
      @JsonKey(name: 'active_subscriptions') required this.activeSubscriptions,
      @JsonKey(name: 'trial_subscriptions') required this.trialSubscriptions,
      @JsonKey(name: 'expired_subscriptions')
      required this.expiredSubscriptions,
      @JsonKey(name: 'active_rooms') required this.activeRooms});

  factory _$MetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MetricsImplFromJson(json);

  @override
  @JsonKey(name: 'total_clients')
  final int totalClients;
  @override
  @JsonKey(name: 'active_subscriptions')
  final int activeSubscriptions;
  @override
  @JsonKey(name: 'trial_subscriptions')
  final int trialSubscriptions;
  @override
  @JsonKey(name: 'expired_subscriptions')
  final int expiredSubscriptions;
  @override
  @JsonKey(name: 'active_rooms')
  final int activeRooms;

  @override
  String toString() {
    return 'Metrics(totalClients: $totalClients, activeSubscriptions: $activeSubscriptions, trialSubscriptions: $trialSubscriptions, expiredSubscriptions: $expiredSubscriptions, activeRooms: $activeRooms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetricsImpl &&
            (identical(other.totalClients, totalClients) ||
                other.totalClients == totalClients) &&
            (identical(other.activeSubscriptions, activeSubscriptions) ||
                other.activeSubscriptions == activeSubscriptions) &&
            (identical(other.trialSubscriptions, trialSubscriptions) ||
                other.trialSubscriptions == trialSubscriptions) &&
            (identical(other.expiredSubscriptions, expiredSubscriptions) ||
                other.expiredSubscriptions == expiredSubscriptions) &&
            (identical(other.activeRooms, activeRooms) ||
                other.activeRooms == activeRooms));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalClients,
      activeSubscriptions,
      trialSubscriptions,
      expiredSubscriptions,
      activeRooms);

  /// Create a copy of Metrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MetricsImplCopyWith<_$MetricsImpl> get copyWith =>
      __$$MetricsImplCopyWithImpl<_$MetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MetricsImplToJson(
      this,
    );
  }
}

abstract class _Metrics implements Metrics {
  const factory _Metrics(
          {@JsonKey(name: 'total_clients') required final int totalClients,
          @JsonKey(name: 'active_subscriptions')
          required final int activeSubscriptions,
          @JsonKey(name: 'trial_subscriptions')
          required final int trialSubscriptions,
          @JsonKey(name: 'expired_subscriptions')
          required final int expiredSubscriptions,
          @JsonKey(name: 'active_rooms') required final int activeRooms}) =
      _$MetricsImpl;

  factory _Metrics.fromJson(Map<String, dynamic> json) = _$MetricsImpl.fromJson;

  @override
  @JsonKey(name: 'total_clients')
  int get totalClients;
  @override
  @JsonKey(name: 'active_subscriptions')
  int get activeSubscriptions;
  @override
  @JsonKey(name: 'trial_subscriptions')
  int get trialSubscriptions;
  @override
  @JsonKey(name: 'expired_subscriptions')
  int get expiredSubscriptions;
  @override
  @JsonKey(name: 'active_rooms')
  int get activeRooms;

  /// Create a copy of Metrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MetricsImplCopyWith<_$MetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
