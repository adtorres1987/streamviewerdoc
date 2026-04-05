import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

@freezed
class Room with _$Room {
  const factory Room({
    required String id,
    required String name,
    /// 6-character join code shown to participants.
    required String code,
    /// One of: 'waiting' | 'active' | 'host_disconnected' | 'closed'
    required String status,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'host_id') required String hostId,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'last_page') int? lastPage,
    @JsonKey(name: 'last_offset') double? lastOffset,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}
