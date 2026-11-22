import 'package:brainbox_core/brainbox_core.dart';

import '../features/auth/domain/auth_models.dart';

/// True when the backend answered 404 for a whole endpoint, i.e. that admin
/// area isn't built on the backend yet (not "this item doesn't exist").
bool isEndpointMissing(Object? error) =>
    error is ApiException &&
    error.statusCode == 404 &&
    !error.code.endsWith('_NOT_FOUND');

/// The admin account was refused (403 `FORBIDDEN`: not an admin).
bool isForbidden(Object? error) =>
    error is ApiException &&
    error.statusCode == 403 &&
    error.code != 'USER_DISABLED';

/// No valid sign-in (401: no token, expired or revoked token).
bool isSignedOutError(Object? error) =>
    error is ApiException && error.statusCode == 401;

/// One sentence for an admin about why a request failed.
///
/// Uses the backend's own message for admin errors (they are written for
/// people, e.g. "A group called 'Unit 6' already exists"), and lists the
/// fields of a validation error instead of "check the highlighted fields".
String adminErrorMessage(Object? error) {
  if (error is ApiException) {
    if (isForbidden(error)) return NotAdminException.message;
    if (isSignedOutError(error)) {
      return 'Your sign-in has expired. Log out and sign in again.';
    }
    if (isEndpointMissing(error)) {
      return 'The server does not support this yet.';
    }
    switch (error.code) {
      case 'USER_DISABLED':
        return 'This account is disabled.';
      case 'USER_NOT_FOUND':
        return 'That student no longer exists. Refresh the list.';
      case 'VALIDATION_ERROR':
        final list = error.details['details'];
        final problems = [
          if (list is List)
            for (final item in list.whereType<Map<dynamic, dynamic>>())
              '${'${item['field']}'.split('.').last}: ${item['message']}',
        ];
        return problems.isEmpty
            ? 'Some values are not valid. Check the form and try again.'
            : 'Check these values: ${problems.join('; ')}.';
      case 'network' || 'timeout' || 'INTERNAL_ERROR' || 'FIREBASE_ERROR':
        return ErrorMessages.fromApi(error);
    }
    // http_400, http_500... carry no message of their own.
    if (error.code.startsWith('http_')) return ErrorMessages.generic;
    return error.message;
  }
  if (error is FormatException) return 'That is not a valid number.';
  return ErrorMessages.of(error);
}
