// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClientDetail _$ClientDetailFromJson(Map<String, dynamic> json) {
  return _ClientDetail.fromJson(json);
}

/// @nodoc
mixin _$ClientDetail {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Backend returns `full_name` (snake_case).
  @JsonKey(name: 'full_name')
  String get fullName => throw _privateConstructorUsedError;

  /// One of: 'pending' | 'active' | 'suspended'
  String get status => throw _privateConstructorUsedError;

  /// One of: 'trial' | 'active' | 'expired' | 'cancelled' — nullable if no subscription.
  @JsonKey(name: 'subscription_status')
  String? get subscriptionStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'trial_ends_at')
  DateTime? get trialEndsAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_period_end')
  DateTime? get currentPeriodEnd => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ClientDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientDetailCopyWith<ClientDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientDetailCopyWith<$Res> {
  factory $ClientDetailCopyWith(
          ClientDetail value, $Res Function(ClientDetail) then) =
      _$ClientDetailCopyWithImpl<$Res, ClientDetail>;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String fullName,
      String status,
      @JsonKey(name: 'subscription_status') String? subscriptionStatus,
      @JsonKey(name: 'trial_ends_at') DateTime? trialEndsAt,
      @JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$ClientDetailCopyWithImpl<$Res, $Val extends ClientDetail>
    implements $ClientDetailCopyWith<$Res> {
  _$ClientDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? status = null,
    Object? subscriptionStatus = freezed,
    Object? trialEndsAt = freezed,
    Object? currentPeriodEnd = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionStatus: freezed == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      trialEndsAt: freezed == trialEndsAt
          ? _value.trialEndsAt
          : trialEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientDetailImplCopyWith<$Res>
    implements $ClientDetailCopyWith<$Res> {
  factory _$$ClientDetailImplCopyWith(
          _$ClientDetailImpl value, $Res Function(_$ClientDetailImpl) then) =
      __$$ClientDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String fullName,
      String status,
      @JsonKey(name: 'subscription_status') String? subscriptionStatus,
      @JsonKey(name: 'trial_ends_at') DateTime? trialEndsAt,
      @JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$ClientDetailImplCopyWithImpl<$Res>
    extends _$ClientDetailCopyWithImpl<$Res, _$ClientDetailImpl>
    implements _$$ClientDetailImplCopyWith<$Res> {
  __$$ClientDetailImplCopyWithImpl(
      _$ClientDetailImpl _value, $Res Function(_$ClientDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? status = null,
    Object? subscriptionStatus = freezed,
    Object? trialEndsAt = freezed,
    Object? currentPeriodEnd = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$ClientDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionStatus: freezed == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      trialEndsAt: freezed == trialEndsAt
          ? _value.trialEndsAt
          : trialEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientDetailImpl implements _ClientDetail {
  const _$ClientDetailImpl(
      {required this.id,
      required this.email,
      @JsonKey(name: 'full_name') required this.fullName,
      required this.status,
      @JsonKey(name: 'subscription_status') this.subscriptionStatus,
      @JsonKey(name: 'trial_ends_at') this.trialEndsAt,
      @JsonKey(name: 'current_period_end') this.currentPeriodEnd,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$ClientDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String email;

  /// Backend returns `full_name` (snake_case).
  @override
  @JsonKey(name: 'full_name')
  final String fullName;

  /// One of: 'pending' | 'active' | 'suspended'
  @override
  final String status;

  /// One of: 'trial' | 'active' | 'expired' | 'cancelled' — nullable if no subscription.
  @override
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;
  @override
  @JsonKey(name: 'trial_ends_at')
  final DateTime? trialEndsAt;
  @override
  @JsonKey(name: 'current_period_end')
  final DateTime? currentPeriodEnd;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ClientDetail(id: $id, email: $email, fullName: $fullName, status: $status, subscriptionStatus: $subscriptionStatus, trialEndsAt: $trialEndsAt, currentPeriodEnd: $currentPeriodEnd, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.trialEndsAt, trialEndsAt) ||
                other.trialEndsAt == trialEndsAt) &&
            (identical(other.currentPeriodEnd, currentPeriodEnd) ||
                other.currentPeriodEnd == currentPeriodEnd) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, fullName, status,
      subscriptionStatus, trialEndsAt, currentPeriodEnd, createdAt);

  /// Create a copy of ClientDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientDetailImplCopyWith<_$ClientDetailImpl> get copyWith =>
      __$$ClientDetailImplCopyWithImpl<_$ClientDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientDetailImplToJson(
      this,
    );
  }
}

abstract class _ClientDetail implements ClientDetail {
  const factory _ClientDetail(
      {required final String id,
      required final String email,
      @JsonKey(name: 'full_name') required final String fullName,
      required final String status,
      @JsonKey(name: 'subscription_status') final String? subscriptionStatus,
      @JsonKey(name: 'trial_ends_at') final DateTime? trialEndsAt,
      @JsonKey(name: 'current_period_end') final DateTime? currentPeriodEnd,
      @JsonKey(name: 'created_at')
      required final DateTime createdAt}) = _$ClientDetailImpl;

  factory _ClientDetail.fromJson(Map<String, dynamic> json) =
      _$ClientDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get email;

  /// Backend returns `full_name` (snake_case).
  @override
  @JsonKey(name: 'full_name')
  String get fullName;

  /// One of: 'pending' | 'active' | 'suspended'
  @override
  String get status;

  /// One of: 'trial' | 'active' | 'expired' | 'cancelled' — nullable if no subscription.
  @override
  @JsonKey(name: 'subscription_status')
  String? get subscriptionStatus;
  @override
  @JsonKey(name: 'trial_ends_at')
  DateTime? get trialEndsAt;
  @override
  @JsonKey(name: 'current_period_end')
  DateTime? get currentPeriodEnd;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ClientDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientDetailImplCopyWith<_$ClientDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
