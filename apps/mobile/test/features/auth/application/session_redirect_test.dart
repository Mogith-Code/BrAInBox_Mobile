import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/auth/application/session_redirect.dart';
import 'package:brainbox_mobile/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _account = AuthAccount(uid: 'u1', email: 'nethmi.p@gmail.com');

SessionState _state({
  bool welcomeSeen = true,
  bool signedIn = true,
  bool verified = true,
  bool profile = true,
  bool diagnostic = false,
  bool skipped = false,
}) => SessionState(
  welcomeSeen: welcomeSeen,
  account: signedIn ? _account : null,
  user: signedIn
      ? AppUser(
          id: 'u1',
          email: 'nethmi.p@gmail.com',
          emailVerified: verified,
          onboarding: OnboardingStatus(
            profileCompleted: profile,
            diagnosticCompleted: diagnostic,
            diagnosticSkipped: skipped,
          ),
        )
      : null,
);

String? _go(SessionState s, String from) => sessionRedirect(AsyncData(s), from);

void main() {
  group('redirect table', () {
    test('first launch, welcome not seen -> welcome carousel', () {
      final s = _state(welcomeSeen: false, signedIn: false);
      expect(_go(s, AppRoutes.splash), AppRoutes.onboarding);
      expect(_go(s, AppRoutes.home), AppRoutes.onboarding);
      expect(_go(s, AppRoutes.onboarding), isNull);
    });

    test('not signed in -> log in (auth screens stay open)', () {
      final s = _state(signedIn: false);
      expect(_go(s, AppRoutes.splash), AppRoutes.login);
      expect(_go(s, AppRoutes.home), AppRoutes.login);
      expect(_go(s, AppRoutes.verifyEmail), AppRoutes.login);
      for (final open in [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.resetCode,
        AppRoutes.newPassword,
        AppRoutes.onboarding,
      ]) {
        expect(_go(s, open), isNull, reason: open);
      }
    });

    test('signed in, email not verified -> check your inbox', () {
      final s = _state(verified: false, profile: false);
      expect(_go(s, AppRoutes.splash), AppRoutes.verifyEmail);
      expect(_go(s, AppRoutes.signup), AppRoutes.verifyEmail);
      expect(_go(s, AppRoutes.home), AppRoutes.verifyEmail);
      expect(_go(s, AppRoutes.verifyEmail), isNull);
    });

    test('verified, profile not completed -> setup', () {
      final s = _state(profile: false);
      expect(_go(s, AppRoutes.splash), AppRoutes.profileSetup);
      expect(_go(s, AppRoutes.verifyEmail), AppRoutes.profileSetup);
      expect(_go(s, AppRoutes.home), AppRoutes.profileSetup);
      expect(_go(s, AppRoutes.profileSetup), isNull);
    });

    test('profile done, diagnostic not done or skipped -> diagnostic', () {
      final s = _state();
      expect(_go(s, AppRoutes.splash), AppRoutes.diagnostic);
      expect(_go(s, AppRoutes.profileSetup), AppRoutes.diagnostic);
      expect(_go(s, AppRoutes.home), AppRoutes.diagnostic);
      for (final open in AppRoutes.diagnosticRoutes) {
        expect(_go(s, open), isNull, reason: open);
      }
    });

    test('diagnostic completed -> home, and any app screen stays open', () {
      final s = _state(diagnostic: true);
      expect(_go(s, AppRoutes.splash), AppRoutes.home);
      expect(_go(s, AppRoutes.login), AppRoutes.home);
      expect(_go(s, AppRoutes.profileSetup), AppRoutes.home);
      expect(_go(s, AppRoutes.home), isNull);
      expect(_go(s, AppRoutes.settings), isNull);
      // The diagnostic can still be opened later (e.g. from Home).
      expect(_go(s, AppRoutes.diagnostic), isNull);
    });

    test('diagnostic skipped -> home', () {
      final s = _state(skipped: true);
      expect(_go(s, AppRoutes.splash), AppRoutes.home);
    });
  });

  test('stays put while the session is loading', () {
    expect(
      sessionRedirect(const AsyncLoading<SessionState>(), AppRoutes.home),
      isNull,
    );
  });

  test('goes to the splash (error + retry) when the session failed', () {
    const error = AsyncError<SessionState>(
      ApiException(code: 'network', message: 'offline'),
      StackTrace.empty,
    );
    expect(sessionRedirect(error, AppRoutes.home), AppRoutes.splash);
    expect(sessionRedirect(error, AppRoutes.splash), isNull);
  });
}
