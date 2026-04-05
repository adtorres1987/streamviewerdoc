import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_participant.freezed.dart';
part 'room_participant.g.dart';

@freezed
class RoomParticipant with _$RoomParticipant {
  const factory RoomParticipant({
    required String id,
    // Backend returns camelCase 'fullName' from /rooms/:id endpoint.
    @JsonKey(name: 'fullName') required String fullName,
    /// One of: 'host' | 'viewer'
    required String role,
    /// One of: 'synced' | 'free' | 'disconnected'
    @JsonKey(name: 'syncState') required String syncState,
    @JsonKey(name: 'lastPage') required int lastPage,
    @JsonKey(name: 'lastOffset') required double lastOffset,
    @JsonKey(name: 'joinedAt') required DateTime joinedAt,
    @JsonKey(name: 'leftAt') DateTime? leftAt,
  }) = _RoomParticipant;

  factory RoomParticipant.fromJson(Map<String, dynamic> json) =>
      _$RoomParticipantFromJson(json);
}
