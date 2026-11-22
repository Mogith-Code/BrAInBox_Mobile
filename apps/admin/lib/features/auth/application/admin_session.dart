import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the person at the keyboard stands. The router guard picks the page
/// from this, so no admin page is built (and no admin request is sent)
/// before we know the user is an admin.
enum AdminSessionStatus {
  /// Firebase or `GET /auth/me` hasn't answered yet.
  checking,

  /// Nobody is signed in (or Firebase isn't configured).
  signedOut,

  /// Signed in, but the role isn't "admin" (the backend answers 403).
  notAdmin,

  /// Signed in as an admin.
  admin,

  /// `GET /auth/me` failed (backend down, account disabled...).
  failed,
}

/// The current [AdminSessionStatus] with the user or the error behind it.
class AdminSession {
  const AdminSession(this.status, {this.user, this.error});

  const AdminSession.checking() : this(AdminSessionStatus.checking);
  const AdminSession.signedOut() : this(AdminSessionStatus.signedOut);

  final AdminSessionStatus status;
  final AppUser? user;
  final Object? error;

  @override
  bool operator ==(Object other) =>
      other is AdminSession &&
      other.status == status &&
      other.user == user &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, user, error);
}

/// The session, from `currentUserProvider` (Firebase + `GET /auth/me`).
///
/// Debug runs with `USE_FAKE_API` or `DISABLE_AUTH_GUARD` count as an admin,
/// so every page can be opened without signing in.
final adminSessionProvider = Provider<AdminSession>((ref) {
  if (Env.useFakeApi || Env.disableAuthGuard) {
    return const AdminSession(AdminSessionStatus.admin);
  }
  if (!FirebaseSetup.isReady) return const AdminSession.signedOut();

  final user = ref.watch(currentUserProvider);
  if (user.hasError) {
    return AdminSession(AdminSessionStatus.failed, error: user.error);
  }
  if (user.isLoading) return const AdminSession.checking();
  final value = user.value;
  if (value == null) return const AdminSession.signedOut();
  return AdminSession(
    value.isAdmin ? AdminSessionStatus.admin : AdminSessionStatus.notAdmin,
    user: value,
  );
});
