import 'package:brainbox_core/brainbox_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/auth_models.dart';
import 'fake_auth_repository.dart';

part 'auth_repository.g.dart';

/// Everything the app needs for sign up, log in, email codes and password
/// reset.
///
/// This (and its fake) is the ONLY place that talks to Firebase Auth.
/// Firebase handles the password; the backend handles the profile, the
/// email code and the reset code.
abstract interface class AuthRepository {
  /// Who is signed in to Firebase right now (null = signed out).
  AuthAccount? get currentAccount;

  /// Emits when someone signs in or out (also from another screen/app).
  Stream<AuthAccount?> accountChanges();

  /// Firebase `createUserWithEmailAndPassword` + set the display name.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  /// Google account -> Firebase credential. Then call [register].
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// Refreshes the Firebase user and its ID token (after verifying email).
  Future<void> reloadAccount();

  /// `POST /auth/register` - creates or updates the backend user (upsert).
  Future<AppUser> register({
    required String fullName,
    String? phone,
    required bool consent,
  });

  /// `GET /auth/me`. Throws [ApiException] `USER_NOT_FOUND` (404) when the
  /// backend has no user for this Firebase account yet.
  Future<AppUser> me();

  /// `DELETE /auth/me` + delete the Firebase user.
  Future<void> deleteAccount();

  /// `POST /auth/email-code/send`
  Future<CodeSent> sendEmailCode();

  /// `POST /auth/email-code/verify`
  Future<AppUser> verifyEmailCode(String code);

  /// `POST /auth/password-reset/send` (no sign-in needed).
  Future<CodeSent> sendResetCode(String email);

  /// `POST /auth/password-reset/verify`
  Future<ResetToken> verifyResetCode({
    required String email,
    required String code,
  });

  /// `POST /auth/password-reset/complete`
  Future<void> completeReset({
    required String resetToken,
    required String newPassword,
  });
}

/// The real repository: Firebase Auth + the BrAInBox API.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.api, {FirebaseAuth? firebaseAuth})
    : _injectedAuth = firebaseAuth;

  final ApiClient api;

  /// Only set by tests (a mocktail mock); the app uses FirebaseAuth.instance.
  final FirebaseAuth? _injectedAuth;

  bool get _firebaseReady => _injectedAuth != null || FirebaseSetup.isReady;

  static const _notConfigured = ApiException(
    code: 'FIREBASE_NOT_CONFIGURED',
    message:
        "Sign-in isn't set up on this build yet. Run `flutterfire configure`, "
        'or start the app with --dart-define=USE_FAKE_API=true.',
  );

  FirebaseAuth get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    if (!FirebaseSetup.isReady) throw _notConfigured;
    return FirebaseAuth.instance;
  }

  static AuthAccount? _toAccount(User? user) => user == null
      ? null
      : AuthAccount(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          emailVerified: user.emailVerified,
        );

  @override
  AuthAccount? get currentAccount =>
      _firebaseReady ? _toAccount(_auth.currentUser) : null;

  @override
  Stream<AuthAccount?> accountChanges() => _firebaseReady
      ? _auth.authStateChanges().map(_toAccount)
      : const Stream.empty();

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signInWithGoogle() async {
    // Opens Google's account picker / web flow and signs in to Firebase.
    // TODO(mogith): add the app's SHA-1 / SHA-256 in the Firebase console,
    // otherwise Google sign-in fails on Android.
    await _auth.signInWithProvider(GoogleAuthProvider());
  }

  @override
  Future<void> signOut() async {
    if (_firebaseReady) await _auth.signOut();
  }

  @override
  Future<void> reloadAccount() async {
    final user = _auth.currentUser;
    await user?.reload();
    await user?.getIdToken(true); // fresh token = fresh email_verified claim
  }

  @override
  Future<AppUser> register({
    required String fullName,
    String? phone,
    required bool consent,
  }) async {
    final json = await api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'full_name': fullName, 'phone': ?phone, 'consent': consent},
    );
    return AppUser.fromJson(json);
  }

  @override
  Future<AppUser> me() async {
    try {
      return AppUser.fromJson(await api.get<Map<String, dynamic>>('/auth/me'));
    } on ApiException catch (e) {
      // A bare 404 means the same as USER_NOT_FOUND.
      if (e.isNotFound && e.code != 'USER_NOT_FOUND') {
        throw ApiException(
          code: 'USER_NOT_FOUND',
          message: e.message,
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    await api.delete<dynamic>('/auth/me');
    await _auth.currentUser?.delete();
  }

  @override
  Future<CodeSent> sendEmailCode() async => CodeSent.fromJson(
    await api.post<Map<String, dynamic>>('/auth/email-code/send'),
  );

  @override
  Future<AppUser> verifyEmailCode(String code) async => AppUser.fromJson(
    await api.post<Map<String, dynamic>>(
      '/auth/email-code/verify',
      data: {'code': code},
    ),
  );

  @override
  Future<CodeSent> sendResetCode(String email) async => CodeSent.fromJson(
    await api.post<Map<String, dynamic>>(
      '/auth/password-reset/send',
      data: {'email': email},
    ),
  );

  @override
  Future<ResetToken> verifyResetCode({
    required String email,
    required String code,
  }) async => ResetToken.fromJson(
    await api.post<Map<String, dynamic>>(
      '/auth/password-reset/verify',
      data: {'email': email, 'code': code},
    ),
  );

  @override
  Future<void> completeReset({
    required String resetToken,
    required String newPassword,
  }) => api.post<dynamic>(
    '/auth/password-reset/complete',
    data: {'reset_token': resetToken, 'new_password': newPassword},
  );
}

/// The real repository, or the in-memory fake with
/// `--dart-define=USE_FAKE_API=true`.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => Env.useFakeApi
    ? FakeAuthRepository(ref.watch(fakeBackendProvider))
    : ApiAuthRepository(ref.watch(apiClientProvider));
