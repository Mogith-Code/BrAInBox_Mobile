import 'package:brainbox_core/brainbox_core.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

/// DEBUG ONLY: [AuthRepository] backed by the in-memory [FakeBackend]
/// (`--dart-define=USE_FAKE_API=true`). Behaves like Firebase + the real
/// API, including the error codes, so every screen state can be tried.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.backend);

  final FakeBackend backend;

  static AuthAccount? _toAccount(FakeAccount? a) => a == null
      ? null
      : AuthAccount(
          uid: a.uid,
          email: a.email,
          displayName: a.fullName,
          emailVerified: a.emailVerified,
        );

  @override
  AuthAccount? get currentAccount => _toAccount(backend.signedIn);

  @override
  Stream<AuthAccount?> accountChanges() => backend.changes.map(_toAccount);

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await backend.delay();
    final key = email.trim().toLowerCase();
    if (backend.accounts.containsKey(key)) {
      throw FakeBackend.firebaseError('email-already-in-use');
    }
    final account = FakeAccount(
      uid: 'fake-${backend.accounts.length + 1}',
      email: key,
      password: password,
      fullName: fullName,
    );
    backend.accounts[key] = account;
    backend.setSignedIn(account);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await backend.delay();
    final account = backend.accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw FakeBackend.firebaseError('invalid-credential');
    }
    backend.setSignedIn(account);
  }

  @override
  Future<void> signInWithGoogle() async {
    await backend.delay();
    // A Google account is already verified by Google.
    const email = 'google.student@gmail.com';
    final account = backend.accounts.putIfAbsent(
      email,
      () => FakeAccount(
        uid: 'fake-google',
        email: email,
        password: '',
        fullName: 'Google Student',
        emailVerified: true,
      ),
    );
    backend.setSignedIn(account);
  }

  @override
  Future<void> signOut() async => backend.setSignedIn(null);

  @override
  Future<void> reloadAccount() async {}

  @override
  Future<AppUser> register({
    required String fullName,
    String? phone,
    required bool consent,
  }) async {
    await backend.delay();
    final account = backend.requireSignedIn();
    if (fullName.isNotEmpty) account.fullName = fullName;
    if (phone != null) account.phone = phone;
    account.registered = true;
    return account.toUser();
  }

  @override
  Future<AppUser> me() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    if (!account.registered) {
      throw const ApiException(
        code: 'USER_NOT_FOUND',
        message: 'User not found.',
        statusCode: 404,
      );
    }
    return account.toUser();
  }

  @override
  Future<void> deleteAccount() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    backend.accounts.remove(account.email);
    backend.setSignedIn(null);
  }

  @override
  Future<CodeSent> sendEmailCode() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    if (account.emailVerified) {
      throw const ApiException(
        code: 'ALREADY_VERIFIED',
        message: 'Already verified.',
        statusCode: 409,
      );
    }
    return CodeSent.fromJson(backend.sendCode(account.email));
  }

  @override
  Future<AppUser> verifyEmailCode(String code) async {
    await backend.delay();
    final account = backend.requireSignedIn();
    backend.checkCode(account.email, code);
    account.emailVerified = true;
    return account.toUser();
  }

  @override
  Future<CodeSent> sendResetCode(String email) async {
    await backend.delay();
    // Like the real API: same answer whether or not the account exists.
    return CodeSent.fromJson(backend.sendCode(email.trim().toLowerCase()));
  }

  @override
  Future<ResetToken> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await backend.delay();
    final key = email.trim().toLowerCase();
    backend.checkCode(key, code);
    if (!backend.accounts.containsKey(key)) {
      // Unknown email: behave exactly like a wrong code.
      throw const ApiException(
        code: 'CODE_INVALID',
        message: 'Wrong code.',
        statusCode: 400,
      );
    }
    return ResetToken(resetToken: backend.createResetToken(key));
  }

  @override
  Future<void> completeReset({
    required String resetToken,
    required String newPassword,
  }) async {
    await backend.delay();
    final email = backend.useResetToken(resetToken);
    if (Validators.password(newPassword) != null) {
      throw const ApiException(
        code: 'WEAK_PASSWORD',
        message: 'Weak password.',
        statusCode: 400,
      );
    }
    backend.accounts[email]?.password = newPassword;
  }
}
