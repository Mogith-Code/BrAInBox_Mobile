import 'package:brainbox_core/brainbox_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// Admin sign-in with Firebase email + password.
///
/// Whether the account is an admin is decided afterwards by
/// `adminSessionProvider` (`GET /auth/me`): a non-admin stays signed in and
/// sees "This account is not an admin" with a Log out button.
abstract interface class AuthRepository {
  /// Throws a [FirebaseAuthException] (wrong password...) or [ApiException].
  Future<void> signIn({
    required String email,
    required String password,
    required bool keepSignedIn,
  });

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<void> signIn({
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
  }

  @override
  Future<void> signOut() async {
    if (FirebaseSetup.isReady) await _auth.signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => FirebaseAuthRepository();
