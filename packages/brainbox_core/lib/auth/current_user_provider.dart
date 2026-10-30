import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
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
  final api = ref.watch(apiClientProvider);
  return FirebaseAuth.instance.authStateChanges().asyncMap(
    (user) => _toAppUser(api, user),
  );
}

Future<AppUser?> _toAppUser(ApiClient api, User? user) async {
  if (user == null) return null;

  // The role ("student" | "admin") and the onboarding flags live in the
  // backend database, so ask GET /auth/me.
  try {
    return AppUser.fromJson(await api.get<Map<String, dynamic>>('/auth/me'));
  } on ApiException catch (e) {
    final notRegistered =
        e.isNotFound ||
        e.code == 'USER_NOT_FOUND' ||
        e.code == 'USER_NOT_REGISTERED';
    if (!notRegistered) rethrow;
    // Signed in to Firebase but unknown to the backend: never an admin.
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? '',
      emailVerified: user.emailVerified,
    );
  }
}
