import 'package:brainbox_core/brainbox_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/auth_models.dart';

part 'auth_repository.g.dart';

/// Admin sign-in: Firebase checks the email + password, then the backend
/// says who the user is (`GET /auth/me`). Only role "admin" may stay in.
abstract interface class AuthRepository {
  /// Returns the admin, or throws [NotAdminException] (after signing out)
  /// or a [FirebaseAuthException] / [ApiException].
  Future<AppUser> signIn({
    required String email,
    required String password,
    required bool keepSignedIn,
  });

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.api);

  final ApiClient api;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
    required bool keepSignedIn,
  }) async {
    if (!FirebaseSetup.isReady) {
      throw const ApiException(
        code: 'AUTH_NOT_CONFIGURED',
        message: 'Firebase is not set up for the admin portal yet.',
      );
    }
    if (kIsWeb) {
      // "Keep me signed in" off = forget the login when the tab closes.
      await _auth.setPersistence(
        keepSignedIn ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final AppUser user;
    try {
      user = AppUser.fromJson(await api.get<Map<String, dynamic>>('/auth/me'));
    } catch (_) {
      await _auth.signOut(); // never stay half signed in
      rethrow;
    }
    if (!user.isAdmin) {
      await _auth.signOut();
      throw const NotAdminException();
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    if (FirebaseSetup.isReady) await _auth.signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) =>
    FirebaseAuthRepository(ref.watch(apiClientProvider));
