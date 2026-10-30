import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in person, as the backend returns it (`UserOut`).
///
/// Returned by `GET /auth/me`, `POST /auth/register` and
/// `POST /auth/email-code/verify`.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    // The backend sends null for accounts without an email (rare). '' keeps
    // the rest of the app simple.
    @Default('') String email,
    @Default('') String fullName,
    String? phone, // +94XXXXXXXXX
    @Default('student') String role, // 'student' or 'admin'
    @Default(false) bool emailVerified,
    @Default(OnboardingStatus()) OnboardingStatus onboarding,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  bool get isAdmin => role == 'admin';

  /// First name for greetings ("Nethmi").
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}

/// Where the student is in the first-run flow.
@freezed
abstract class OnboardingStatus with _$OnboardingStatus {
  const factory OnboardingStatus({
    @Default(false) bool profileCompleted,
    @Default(false) bool diagnosticCompleted,
    @Default(false) bool diagnosticSkipped,
  }) = _OnboardingStatus;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStatusFromJson(json);
}
