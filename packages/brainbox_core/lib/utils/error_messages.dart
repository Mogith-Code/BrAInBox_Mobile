import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import 'firebase_error_mapper.dart';

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
    final known = fromCode(error.code, retryAfter: error.retryAfter);
    return known ?? error.message;
  }

  /// Friendly text for a backend error code, or null if we don't know it.
  static String? fromCode(String code, {int? retryAfter}) => switch (code) {
    // Network / transport
    'network' => 'No internet connection. Check it and try again.',
    'timeout' => 'The server took too long to respond. Please try again.',
    // Auth
    'USER_NOT_FOUND' => 'We couldn\'t find your account. Please sign up.',
    'ALREADY_VERIFIED' => 'Your email is already verified.',
    'RESEND_TOO_SOON' =>
      retryAfter == null
          ? 'Please wait a moment before asking for a new code.'
          : 'Please wait $retryAfter seconds before asking for a new code.',
    'CODE_INVALID' => 'That code isn\'t right. Check it and try again.',
    'CODE_EXPIRED' => 'That code has expired. Ask for a new one.',
    'TOO_MANY_ATTEMPTS' => 'Too many wrong tries. Ask for a new code.',
    'RESET_TOKEN_INVALID' => 'This reset link has expired. Please start again.',
    'WEAK_PASSWORD' =>
      'Choose a stronger password (8+ characters with a letter and a number).',
    // Profile
    'PROFILE_INCOMPLETE' => 'Please finish every step before continuing.',
    // Diagnostic
    'NOT_ENOUGH_QUESTIONS' =>
      'We\'re still adding questions. You can start learning now.',
    'DIAGNOSTIC_NOT_FOUND' => 'We couldn\'t find your diagnostic result.',
    _ => null,
  };
}
