import 'package:freezed_annotation/freezed_annotation.dart';

// The signed-in user (UserOut) is shared, so it lives in brainbox_core.
export 'package:brainbox_core/brainbox_core.dart'
    show AppUser, OnboardingStatus;

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Response of `POST /auth/email-code/send` and
/// `POST /auth/password-reset/send`.
@freezed
abstract class CodeSent with _$CodeSent {
  const factory CodeSent({
    @Default(true) bool sent,
    @Default(60) int resendIn, // seconds until "Resend code" is allowed
    @Default(600) int expiresIn, // seconds the code stays valid
    String? devCode, // only when the backend runs with DEV_EXPOSE_CODES=true
  }) = _CodeSent;

  factory CodeSent.fromJson(Map<String, dynamic> json) =>
      _$CodeSentFromJson(json);
}

/// Response of `POST /auth/password-reset/verify`. Kept in memory only.
@freezed
abstract class ResetToken with _$ResetToken {
  const factory ResetToken({
    required String resetToken,
    @Default(600) int expiresIn,
  }) = _ResetToken;

  factory ResetToken.fromJson(Map<String, dynamic> json) =>
      _$ResetTokenFromJson(json);
}

/// What "Check your inbox" is checking.
enum InboxMode {
  /// After sign up: confirm the email address.
  verifyEmail,

  /// After "Forgot password": prove you own the email, then set a new one.
  resetPassword,
}

/// The Firebase side of the signed-in person (what Firebase knows before
/// the backend answers).
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final bool emailVerified;
}
