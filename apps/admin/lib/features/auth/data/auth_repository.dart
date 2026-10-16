import 'package:brainbox_core/brainbox_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/auth_models.dart';

part 'auth_repository.g.dart';

/// Data layer for the Auth feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class AuthRepository {
  AuthRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Auth screen.
  Future<AuthSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/me');
    // return AuthSummary.fromJson(json);
    return const AuthSummary(
      title: 'Admin login',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add signIn / signUp / sendPasswordReset / sendEmailVerification
  // here using FirebaseAuth.instance. Map errors with FirebaseErrorMapper.

  /// Signs the user out of Firebase (no-op if Firebase is not configured).
  Future<void> signOut() async {
    if (!FirebaseSetup.isReady) return;
    await FirebaseAuth.instance.signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(apiClientProvider));
