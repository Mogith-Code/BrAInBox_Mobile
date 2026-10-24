import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/application/auth_flow_controllers.dart';
import 'package:brainbox_mobile/features/auth/domain/auth_models.dart';
import 'package:brainbox_mobile/features/auth/presentation/check_inbox_screen.dart';
import 'package:brainbox_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:brainbox_mobile/features/auth/presentation/login_screen.dart';
import 'package:brainbox_mobile/features/auth/presentation/new_password_screen.dart';
import 'package:brainbox_mobile/features/auth/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_app.dart';

/// Pumps [screen] at [path] in a small router where every other route just
/// shows its path as text (so we can check where buttons go).
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required String path,
  ProviderContainer? container,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A container passed in is disposed by the test itself.
  final c = container ?? fakeContainer();
  if (container == null) addTearDown(c.dispose);
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (_, _) => screen),
      for (final other in {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
        AppRoutes.resetCode,
        AppRoutes.newPassword,
        AppRoutes.profileSetup,
      }..remove(path))
        GoRoute(
          path: other,
          builder: (_, _) => Scaffold(body: Text('AT $other')),
        ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Create account', () {
    testWidgets('shows the Figma fields', (tester) async {
      await _pump(tester, const SignupScreen(), path: AppRoutes.signup);
      for (final text in [
        'Create your account',
        'Takes less than a minute.',
        'Full name',
        'Email',
        'Phone',
        'Password',
        'Create account',
        'Sign up with Google',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('validates before calling the backend', (tester) async {
      await _pump(tester, const SignupScreen(), path: AppRoutes.signup);
      await tester.ensureVisible(find.text('Create account').last);
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Please agree to continue'), findsOneWidget);
    });

    testWidgets('error state: email already in use', (tester) async {
      await _pump(tester, const SignupScreen(), path: AppRoutes.signup);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nethmi Perera');
      await tester.enterText(fields.at(1), 'nethmi.p@gmail.com'); // seeded
      await tester.enterText(fields.at(3), 'Mito2027');
      await tester.pump();
      expect(find.text('Good'), findsOneWidget); // strength meter
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Create account').last);
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(
        find.text('An account already exists for that email.'),
        findsOneWidget,
      );
    });

    testWidgets('success goes to Check your inbox', (tester) async {
      await _pump(tester, const SignupScreen(), path: AppRoutes.signup);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Kavi Silva');
      await tester.enterText(fields.at(1), 'kavi@gmail.com');
      await tester.enterText(fields.at(2), '77 123 4567');
      await tester.enterText(fields.at(3), 'Mito2027');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Create account').last);
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(find.text('AT ${AppRoutes.verifyEmail}'), findsOneWidget);
    });
  });

  group('Log in', () {
    testWidgets('data state shows the Figma text', (tester) async {
      await _pump(tester, const LoginScreen(), path: AppRoutes.login);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('error state: wrong password', (tester) async {
      await _pump(tester, const LoginScreen(), path: AppRoutes.login);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'nethmi.p@gmail.com');
      await tester.enterText(fields.at(1), 'wrong');
      await tester.tap(find.text('Log in').last);
      await tester.pumpAndSettle();
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
    });

    testWidgets('loading state shows a spinner on the button', (tester) async {
      final c = fakeContainer(
        backend: FakeBackend(latency: const Duration(seconds: 1)),
      );
      await _pump(
        tester,
        const LoginScreen(),
        path: AppRoutes.login,
        container: c,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'nethmi.p@gmail.com');
      await tester.enterText(fields.at(1), 'Mito2027');
      await tester.tap(find.text('Log in').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });

    testWidgets('Forgot password? opens the reset screen', (tester) async {
      await _pump(tester, const LoginScreen(), path: AppRoutes.login);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${AppRoutes.forgotPassword}'), findsOneWidget);
    });
  });

  testWidgets('Forgot password sends a code and opens the inbox', (
    tester,
  ) async {
    await _pump(
      tester,
      const ForgotPasswordScreen(),
      path: AppRoutes.forgotPassword,
    );
    expect(find.text('Forgot your password?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'nethmi.p@gmail.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.resetCode}'), findsOneWidget);
  });

  group('Check your inbox', () {
    testWidgets('reset mode: countdown, debug code, wrong code', (
      tester,
    ) async {
      final c = fakeContainer();
      // Real clock: the fake backend's delays are timers.
      await tester.runAsync(
        () => c
            .read(forgotPasswordControllerProvider.notifier)
            .submit('nethmi.p@gmail.com'),
      );
      await _pump(
        tester,
        const CheckInboxScreen(mode: InboxMode.resetPassword),
        path: AppRoutes.resetCode,
        container: c,
      );

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('nethmi.p@gmail.com', findRichText: true), findsNothing);
      expect(
        find.textContaining('nethmi.p@gmail.com', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Resend code in', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Debug code: 482715'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('otp-input')), '111111');
      await tester.pumpAndSettle();
      expect(
        find.text("That code isn't right. Check it and try again."),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const ValueKey('otp-input')), '482715');
      await tester.pumpAndSettle();
      expect(find.text('AT ${AppRoutes.newPassword}'), findsOneWidget);

      // Unmount and dispose so the inbox's countdown timer is cancelled.
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await tester.pump();
    });
  });

  testWidgets('Set a new password: RESET_TOKEN_INVALID offers Start again', (
    tester,
  ) async {
    await _pump(tester, const NewPasswordScreen(), path: AppRoutes.newPassword);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NewPass123');
    await tester.enterText(fields.at(1), 'NewPass123');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('This reset link has expired. Please start again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Start again'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.forgotPassword}'), findsOneWidget);
  });
}
