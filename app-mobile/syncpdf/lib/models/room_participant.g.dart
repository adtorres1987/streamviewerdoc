// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomParticipantImpl _$$RoomParticipantImplFromJson(
        Map<String, dynamic> json) =>
    _$RoomParticipantImpl(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      syncState: json['syncState'] as String,
      lastPage: (json['lastPage'] as num).toInt(),
      lastOffset: (json['lastOffset'] as num).toDouble(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
    );

Map<String, dynamic> _$$RoomParticipantImplToJson(
        _$RoomParticipantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'role': instance.role,
      'syncState': instance.syncState,
      'lastPage': instance.lastPage,
      'lastOffset': instance.lastOffset,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
    };
