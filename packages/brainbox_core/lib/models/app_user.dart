import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in person (student or admin).
///
// TODO(mogith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid, // Firebase uid
    required String email,
    String? displayName,
    @Default('student') String role, // 'student' or 'admin'
    @Default(false) bool emailVerified,
    String? stream, // A/L stream, e.g. 'Biology'
    int? examYear, // e.g. 2027
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  bool get isAdmin => role == 'admin';
}
