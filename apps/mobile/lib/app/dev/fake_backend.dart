import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_backend.g.dart';

/// DEBUG ONLY: an in-memory stand-in for the BrAInBox backend AND Firebase
/// Auth. Used when the app runs with `--dart-define=USE_FAKE_API=true`, and
/// by tests.
///
/// Every feature's fake repository reads and writes this one object, so the
/// whole first-run flow works without a server:
/// sign up -> code -> profile -> diagnostic -> home.
///
/// Ready-made account (onboarding finished, lands on Home):
///   nethmi.p@gmail.com / Mito2027
/// The email / reset code is always [devCode] (also shown in the debug strip).
class FakeBackend {
  FakeBackend({this.latency = const Duration(milliseconds: 350)}) {
    final nethmi = FakeAccount(
      uid: 'fake-nethmi',
      email: 'nethmi.p@gmail.com',
      password: 'Mito2027',
      fullName: 'Nethmi Perera',
      phone: '+94771234567',
      emailVerified: true,
      registered: true,
      onboarding: const OnboardingStatus(
        profileCompleted: true,
        diagnosticCompleted: true,
      ),
    );
    nethmi.profile.addAll({
      'stream': 'biological_science',
      'subject': 'biology',
      'exam_year': 2027,
      'target_grade': 'A',
      'confidence': 50,
      'study_days': ['mon', 'tue', 'thu', 'sat', 'sun'],
      'hours_per_day': 2,
      'preferred_time': 'evening',
    });
    accounts[nethmi.email] = nethmi;
  }

  /// The 6-digit code every fake email contains.
  static const devCode = '482715';

  /// Seconds before "Resend code" is allowed (matches the Figma "0:42").
  static const resendIn = 42;

  /// Pretend network delay, so loading states are visible.
  final Duration latency;

  final Map<String, FakeAccount> accounts = {};
  FakeAccount? signedIn;
  final _changes = StreamController<FakeAccount?>.broadcast();

  /// email -> when the last code was sent (for RESEND_TOO_SOON).
  final Map<String, DateTime> _lastCodeAt = {};

  /// email -> wrong code attempts (5 = TOO_MANY_ATTEMPTS).
  final Map<String, int> _wrongAttempts = {};

  /// reset token -> email
  final Map<String, String> _resetTokens = {};

  Stream<FakeAccount?> get changes => _changes.stream;

  Future<void> delay() => Future<void>.delayed(latency);

  void setSignedIn(FakeAccount? account) {
    signedIn = account;
    _changes.add(account);
  }

  /// The signed-in account, or a 401 like the real API.
  FakeAccount requireSignedIn() {
    final account = signedIn;
    if (account == null) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Please sign in again.',
        statusCode: 401,
      );
    }
    return account;
  }

  // ------------------------------------------------------------- codes

  /// Simulates sending a code to [email] (respects the resend wait).
  Map<String, dynamic> sendCode(String email) {
    final last = _lastCodeAt[email];
    if (last != null) {
      final waited = DateTime.now().difference(last).inSeconds;
      if (waited < resendIn) {
        throw ApiException(
          code: 'RESEND_TOO_SOON',
          message: 'Please wait before asking for a new code.',
          statusCode: 429,
          retryAfter: resendIn - waited,
        );
      }
    }
    _lastCodeAt[email] = DateTime.now();
    _wrongAttempts[email] = 0;
    return {
      'sent': true,
      'resend_in': resendIn,
      'expires_in': 600,
      'dev_code': devCode,
    };
  }

  /// Checks a code typed for [email].
  void checkCode(String email, String code) {
    final attempts = _wrongAttempts[email] ?? 0;
    if (attempts >= 5) {
      throw const ApiException(
        code: 'TOO_MANY_ATTEMPTS',
        message: 'Too many attempts.',
        statusCode: 429,
      );
    }
    if (code == '000000') {
      throw const ApiException(
        code: 'CODE_EXPIRED',
        message: 'Code expired.',
        statusCode: 400,
      );
    }
    if (code != devCode) {
      _wrongAttempts[email] = attempts + 1;
      throw const ApiException(
        code: 'CODE_INVALID',
        message: 'Wrong code.',
        statusCode: 400,
      );
    }
  }

  String createResetToken(String email) {
    final token = 'reset-${DateTime.now().microsecondsSinceEpoch}';
    _resetTokens[token] = email;
    return token;
  }

  /// The email a reset token belongs to (and forgets the token).
  String useResetToken(String token) {
    final email = _resetTokens.remove(token);
    if (email == null) {
      throw const ApiException(
        code: 'RESET_TOKEN_INVALID',
        message: 'Reset token invalid.',
        statusCode: 400,
      );
    }
    return email;
  }

  /// Like Firebase's error for a wrong email / password.
  static FirebaseAuthException firebaseError(String code) =>
      FirebaseAuthException(code: code);
}

/// One fake user: Firebase part (email, password) + backend part.
class FakeAccount {
  FakeAccount({
    required this.uid,
    required this.email,
    required this.password,
    this.fullName = '',
    this.phone,
    this.emailVerified = false,
    this.registered = false,
    this.onboarding = const OnboardingStatus(),
  });

  final String uid;
  final String email;
  String password;
  String fullName;
  String? phone;
  bool emailVerified;

  /// `POST /auth/register` was called (backend user exists).
  bool registered;
  OnboardingStatus onboarding;

  /// Saved profile fields (snake_case, as sent by `PATCH /profile`).
  final Map<String, dynamic> profile = {};

  /// The `UserOut` JSON the real backend would return.
  AppUser toUser() => AppUser(
    id: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    emailVerified: emailVerified,
    onboarding: onboarding,
  );
}

/// One fake backend for the whole app session.
@Riverpod(keepAlive: true)
FakeBackend fakeBackend(Ref ref) => FakeBackend();
