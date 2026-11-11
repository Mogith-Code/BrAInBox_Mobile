// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AppUser;

/// The account signed in fine but its role (from `GET /auth/me`) is not
/// "admin". The portal signs it out again.
class NotAdminException implements Exception {
  const NotAdminException();

  static const message = 'This account is not an admin.';

  @override
  String toString() => message;
}
