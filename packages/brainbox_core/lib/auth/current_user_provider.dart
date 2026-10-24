import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/firebase_setup.dart';
import '../models/app_user.dart';

part 'current_user_provider.g.dart';

/// The signed-in user, or `null` when signed out.
///
/// Also `null` when Firebase is not configured yet, so the apps still run.
///
/// ```dart
/// final user = ref.watch(currentUserProvider).value; // AppUser?
/// ```
@Riverpod(keepAlive: true)
Stream<AppUser?> currentUser(Ref ref) {
  if (!FirebaseSetup.isReady) return Stream.value(null);
  // idTokenChanges also fires when the token (and its claims) refresh.
  return FirebaseAuth.instance.idTokenChanges().asyncMap(_toAppUser);
}

Future<AppUser?> _toAppUser(User? user) async {
  if (user == null) return null;

  // TODO(mogith): confirm with the backend where the role comes from.
  // Assumption: the backend sets a Firebase custom claim `role`
  // ("student" | "admin"). Alternative: call GET /me and read `role`.
  final token = await user.getIdTokenResult();
  final role = token.claims?['role'] as String? ?? 'student';

  // The backend profile (onboarding flags, phone) comes from GET /auth/me;
  // this provider only knows what Firebase knows.
  return AppUser(
    id: user.uid,
    email: user.email ?? '',
    fullName: user.displayName ?? '',
    emailVerified: user.emailVerified,
    role: role,
  );
}
