import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

@freezed
class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String id,
    // Backend returns camelCase 'fullName' from /groups/:id endpoint.
    @JsonKey(name: 'fullName') required String fullName,
    required String email,
    /// One of: 'owner' | 'member'
    required String role,
    // Backend returns camelCase 'joinedAt'.
    @JsonKey(name: 'joinedAt') required DateTime joinedAt,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
