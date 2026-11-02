import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import 'firebase_error_mapper.dart';
import 'formatters.dart';

/// Turns ANY error into one friendly sentence for the student.
///
/// The ONE place that maps backend error codes (`ApiException.code`) to
/// text. Firebase errors go through [FirebaseErrorMapper].
///
/// ```dart
/// error: (e, _) => ErrorBanner(message: ErrorMessages.of(e)),
/// ```
abstract final class ErrorMessages {
  static const generic = 'Something went wrong. Please try again.';

  /// Message for any error object.
  static String of(Object? error) {
    if (error is ApiException) return fromApi(error);
    if (error is FirebaseAuthException) {
      return FirebaseErrorMapper.message(error);
    }
    return generic;
  }

  /// Message for a backend error. Uses our own text for known codes and
  /// the backend's message otherwise.
  static String fromApi(ApiException error) {
    final left = error.attemptsLeft;
    if (error.code == 'CODE_INVALID' && left != null) {
      return left == 1
          ? 'That code isn\'t right. 1 try left.'
          : 'That code isn\'t right. $left tries left.';
    }
    final known = fromCode(error.code, retryAfter: error.retryAfter);
    return known ?? error.message;
  }

  /// The message for one form field (`'email'`, `'phone'`, `'password'`,
  /// `'consent'`...), or null when [error] isn't about that field.
  ///
  /// Screens show it under the field instead of above the button.
  static String? forField(Object? error, String field) {
    if (error is FirebaseAuthException) {
      final firebaseField = switch (error.code) {
        'email-already-in-use' || 'invalid-email' => 'email',
        'weak-password' => 'password',
        _ => null,
      };
      return firebaseField == field ? FirebaseErrorMapper.message(error) : null;
    }
    if (error is! ApiException) return null;
    final raw = error.fieldErrors[field];
    if (raw == null) return null;
    return fromCode(error.code) ?? raw;
  }

  /// Whether every problem in [error] is shown under a field (so the screen
  /// doesn't need to repeat it above the button).
  static bool isOnlyFieldError(Object? error) {
    if (error is FirebaseAuthException) {
      return const {
        'email-already-in-use',
        'invalid-email',
        'weak-password',
      }.contains(error.code);
    }
    return error is ApiException && error.fieldErrors.isNotEmpty;
  }

  /// Friendly text for a backend error code, or null if we don't know it.
  static String? fromCode(String code, {int? retryAfter}) => switch (code) {
    // Network / transport
    'network' => 'No internet connection. Check it and try again.',
    'timeout' => 'The server took too long to respond. Please try again.',
    'INTERNAL_ERROR' || 'FIREBASE_ERROR' => generic,
    'VALIDATION_ERROR' => 'Please check the highlighted fields.',
    // Auth
    'USER_NOT_FOUND' ||
    'USER_NOT_REGISTERED' => 'We couldn\'t find your account. Please sign up.',
    'USER_DISABLED' => 'This account is disabled. Contact your teacher.',
    'EMAIL_IN_USE' => 'This email belongs to another account.',
    'INVALID_PHONE' => 'Enter a Sri Lankan mobile number, e.g. 077 123 4567.',
    'CONSENT_REQUIRED' => 'Please agree to continue.',
    'EMAIL_SEND_FAILED' ||
    'EMAIL_NOT_CONFIGURED' => 'Could not send the email. Please try again.',
    'NO_EMAIL' => 'This account has no email address.',
    'ALREADY_VERIFIED' => 'Your email is already verified.',
    'RESEND_TOO_SOON' =>
      retryAfter == null
          ? 'Please wait a moment before asking for a new code.'
          : 'Please wait $retryAfter seconds before asking for a new code.',
    'CODE_INVALID' => 'That code isn\'t right. Check it and try again.',
    'CODE_EXPIRED' => 'That code has expired. Ask for a new one.',
    'TOO_MANY_ATTEMPTS' => 'Too many wrong tries. Ask for a new code.',
    'RESET_TOKEN_INVALID' =>
      'This reset has expired. Start again from Forgot password.',
    'WEAK_PASSWORD' =>
      'Choose a stronger password (8+ characters with a letter and a number).',
    // Profile
    'PROFILE_INCOMPLETE' => 'Please finish every step before continuing.',
    // Diagnostic
    'NOT_ENOUGH_QUESTIONS' =>
      'We\'re still adding questions. You can start learning now.',
    'DIAGNOSTIC_NOT_FOUND' => 'We couldn\'t find your diagnostic result.',
    // Visuals and AI jobs
    'VISUAL_NOT_FOUND' => 'This visual isn\'t available.',
    'TOPIC_NOT_FOUND' => 'We couldn\'t find this topic.',
    'JOB_NOT_FOUND' => 'We lost track of this request. Please try again.',
    'ALREADY_REPORTED' =>
      'You already reported this visual. An admin will check it soon.',
    'VISUAL_LIMIT_REACHED' =>
      retryAfter == null
          ? 'You\'ve made today\'s visuals. Try again tomorrow.'
          : 'You\'ve made today\'s visuals. '
                'Try again in ${Formatters.waitTime(retryAfter)}.',
    'NOT_BIOLOGY' => 'I can only draw Biology visuals.',
    'AI_DAILY_LIMIT' =>
      'Today\'s free AI requests are used up. Please try again tomorrow.',
    'AI_SERVICE_UNAVAILABLE' =>
      'The AI is busy right now. Please try again in a few minutes.',
    'FILE_NOT_FOUND' => 'This picture couldn\'t be loaded.',
    _ => null,
  };
}
