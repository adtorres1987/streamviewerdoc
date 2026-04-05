import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    /// Backend returns `full_name` (snake_case).
    @JsonKey(name: 'full_name') required String fullName,
    /// One of: 'client' | 'admin' | 'superadmin'
    required String role,
    /// One of: 'pending' | 'active' | 'suspended'
    required String status,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
