// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomImpl _$$RoomImplFromJson(Map<String, dynamic> json) => _$RoomImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      status: json['status'] as String,
      groupId: json['group_id'] as String,
      hostId: json['host_id'] as String,
      fileName: json['file_name'] as String?,
      lastPage: (json['last_page'] as num?)?.toInt(),
      lastOffset: (json['last_offset'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
    );

Map<String, dynamic> _$$RoomImplToJson(_$RoomImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'status': instance.status,
      'group_id': instance.groupId,
      'host_id': instance.hostId,
      'file_name': instance.fileName,
      'last_page': instance.lastPage,
      'last_offset': instance.lastOffset,
      'created_at': instance.createdAt.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
    };
