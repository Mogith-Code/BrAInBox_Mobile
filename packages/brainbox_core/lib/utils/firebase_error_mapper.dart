import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase Auth errors into friendly messages for students.
///
/// ```dart
/// } on FirebaseAuthException catch (e) {
///   showError(FirebaseErrorMapper.message(e));
/// }
/// ```
abstract final class FirebaseErrorMapper {
  static const _fallback = 'Something went wrong. Please try again.';

  static String message(Object error) {
    if (error is FirebaseAuthException) return fromCode(error.code);
    return _fallback;
  }

  static String fromCode(String code) => switch (code) {
    'invalid-email' => 'That email address does not look right.',
    'user-disabled' => 'This account has been suspended. Contact support.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Choose a stronger password (at least 8 characters).',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'No internet connection. Please try again.',
    'requires-recent-login' => 'Please sign in again to continue.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',
    _ => _fallback,
  };
}
