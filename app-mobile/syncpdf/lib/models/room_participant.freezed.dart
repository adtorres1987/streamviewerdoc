// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoomParticipant _$RoomParticipantFromJson(Map<String, dynamic> json) {
  return _RoomParticipant.fromJson(json);
}

/// @nodoc
mixin _$RoomParticipant {
  String get id =>
      throw _privateConstructorUsedError; // Backend returns camelCase 'fullName' from /rooms/:id endpoint.
  @JsonKey(name: 'fullName')
  String get fullName => throw _privateConstructorUsedError;

  /// One of: 'host' | 'viewer'
  String get role => throw _privateConstructorUsedError;

  /// One of: 'synced' | 'free' | 'disconnected'
  @JsonKey(name: 'syncState')
  String get syncState => throw _privateConstructorUsedError;
  @JsonKey(name: 'lastPage')
  int get lastPage => throw _privateConstructorUsedError;
  @JsonKey(name: 'lastOffset')
  double get lastOffset => throw _privateConstructorUsedError;
  @JsonKey(name: 'joinedAt')
  DateTime get joinedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'leftAt')
  DateTime? get leftAt => throw _privateConstructorUsedError;

  /// Serializes this RoomParticipant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomParticipant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomParticipantCopyWith<RoomParticipant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomParticipantCopyWith<$Res> {
  factory $RoomParticipantCopyWith(
          RoomParticipant value, $Res Function(RoomParticipant) then) =
      _$RoomParticipantCopyWithImpl<$Res, RoomParticipant>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullName') String fullName,
      String role,
      @JsonKey(name: 'syncState') String syncState,
      @JsonKey(name: 'lastPage') int lastPage,
      @JsonKey(name: 'lastOffset') double lastOffset,
      @JsonKey(name: 'joinedAt') DateTime joinedAt,
      @JsonKey(name: 'leftAt') DateTime? leftAt});
}

/// @nodoc
class _$RoomParticipantCopyWithImpl<$Res, $Val extends RoomParticipant>
    implements $RoomParticipantCopyWith<$Res> {
  _$RoomParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomParticipant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? role = null,
    Object? syncState = null,
    Object? lastPage = null,
    Object? lastOffset = null,
    Object? joinedAt = null,
    Object? leftAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      syncState: null == syncState
          ? _value.syncState
          : syncState // ignore: cast_nullable_to_non_nullable
              as String,
      lastPage: null == lastPage
          ? _value.lastPage
          : lastPage // ignore: cast_nullable_to_non_nullable
              as int,
      lastOffset: null == lastOffset
          ? _value.lastOffset
          : lastOffset // ignore: cast_nullable_to_non_nullable
              as double,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomParticipantImplCopyWith<$Res>
    implements $RoomParticipantCopyWith<$Res> {
  factory _$$RoomParticipantImplCopyWith(_$RoomParticipantImpl value,
          $Res Function(_$RoomParticipantImpl) then) =
      __$$RoomParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullName') String fullName,
      String role,
      @JsonKey(name: 'syncState') String syncState,
      @JsonKey(name: 'lastPage') int lastPage,
      @JsonKey(name: 'lastOffset') double lastOffset,
      @JsonKey(name: 'joinedAt') DateTime joinedAt,
      @JsonKey(name: 'leftAt') DateTime? leftAt});
}

/// @nodoc
class __$$RoomParticipantImplCopyWithImpl<$Res>
    extends _$RoomParticipantCopyWithImpl<$Res, _$RoomParticipantImpl>
    implements _$$RoomParticipantImplCopyWith<$Res> {
  __$$RoomParticipantImplCopyWithImpl(
      _$RoomParticipantImpl _value, $Res Function(_$RoomParticipantImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoomParticipant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? role = null,
    Object? syncState = null,
    Object? lastPage = null,
    Object? lastOffset = null,
    Object? joinedAt = null,
    Object? leftAt = freezed,
  }) {
    return _then(_$RoomParticipantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      syncState: null == syncState
          ? _value.syncState
          : syncState // ignore: cast_nullable_to_non_nullable
              as String,
      lastPage: null == lastPage
          ? _value.lastPage
          : lastPage // ignore: cast_nullable_to_non_nullable
              as int,
      lastOffset: null == lastOffset
          ? _value.lastOffset
          : lastOffset // ignore: cast_nullable_to_non_nullable
              as double,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomParticipantImpl implements _RoomParticipant {
  const _$RoomParticipantImpl(
      {required this.id,
      @JsonKey(name: 'fullName') required this.fullName,
      required this.role,
      @JsonKey(name: 'syncState') required this.syncState,
      @JsonKey(name: 'lastPage') required this.lastPage,
      @JsonKey(name: 'lastOffset') required this.lastOffset,
      @JsonKey(name: 'joinedAt') required this.joinedAt,
      @JsonKey(name: 'leftAt') this.leftAt});

  factory _$RoomParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomParticipantImplFromJson(json);

  @override
  final String id;
// Backend returns camelCase 'fullName' from /rooms/:id endpoint.
  @override
  @JsonKey(name: 'fullName')
  final String fullName;

  /// One of: 'host' | 'viewer'
  @override
  final String role;

  /// One of: 'synced' | 'free' | 'disconnected'
  @override
  @JsonKey(name: 'syncState')
  final String syncState;
  @override
  @JsonKey(name: 'lastPage')
  final int lastPage;
  @override
  @JsonKey(name: 'lastOffset')
  final double lastOffset;
  @override
  @JsonKey(name: 'joinedAt')
  final DateTime joinedAt;
  @override
  @JsonKey(name: 'leftAt')
  final DateTime? leftAt;

  @override
  String toString() {
    return 'RoomParticipant(id: $id, fullName: $fullName, role: $role, syncState: $syncState, lastPage: $lastPage, lastOffset: $lastOffset, joinedAt: $joinedAt, leftAt: $leftAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomParticipantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.syncState, syncState) ||
                other.syncState == syncState) &&
            (identical(other.lastPage, lastPage) ||
                other.lastPage == lastPage) &&
            (identical(other.lastOffset, lastOffset) ||
                other.lastOffset == lastOffset) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.leftAt, leftAt) || other.leftAt == leftAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName, role, syncState,
      lastPage, lastOffset, joinedAt, leftAt);

  /// Create a copy of RoomParticipant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomParticipantImplCopyWith<_$RoomParticipantImpl> get copyWith =>
      __$$RoomParticipantImplCopyWithImpl<_$RoomParticipantImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomParticipantImplToJson(
      this,
    );
  }
}

abstract class _RoomParticipant implements RoomParticipant {
  const factory _RoomParticipant(
      {required final String id,
      @JsonKey(name: 'fullName') required final String fullName,
      required final String role,
      @JsonKey(name: 'syncState') required final String syncState,
      @JsonKey(name: 'lastPage') required final int lastPage,
      @JsonKey(name: 'lastOffset') required final double lastOffset,
      @JsonKey(name: 'joinedAt') required final DateTime joinedAt,
      @JsonKey(name: 'leftAt') final DateTime? leftAt}) = _$RoomParticipantImpl;

  factory _RoomParticipant.fromJson(Map<String, dynamic> json) =
      _$RoomParticipantImpl.fromJson;

  @override
  String
      get id; // Backend returns camelCase 'fullName' from /rooms/:id endpoint.
  @override
  @JsonKey(name: 'fullName')
  String get fullName;

  /// One of: 'host' | 'viewer'
  @override
  String get role;

  /// One of: 'synced' | 'free' | 'disconnected'
  @override
  @JsonKey(name: 'syncState')
  String get syncState;
  @override
  @JsonKey(name: 'lastPage')
  int get lastPage;
  @override
  @JsonKey(name: 'lastOffset')
  double get lastOffset;
  @override
  @JsonKey(name: 'joinedAt')
  DateTime get joinedAt;
  @override
  @JsonKey(name: 'leftAt')
  DateTime? get leftAt;

  /// Create a copy of RoomParticipant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomParticipantImplCopyWith<_$RoomParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
