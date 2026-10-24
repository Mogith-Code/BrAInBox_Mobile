// End-to-end: the whole first-run flow on the fake API, on a real device.
//   cd apps/mobile
//   flutter test integration_test/onboarding_flow_test.dart
import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/app.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fake_app.dart';

Future<void> _startApp(WidgetTester tester, FakeBackend backend) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: fakeOverrides(backend),
      child: const BrainBoxApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Closes the on-screen keyboard (it covers the bottom of the form).
Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await _hideKeyboard(tester);
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash -> welcome -> sign up -> code -> setup -> diagnostic '
      '-> result -> home', (tester) async {
    final backend = FakeBackend(latency: const Duration(milliseconds: 50));
    await _startApp(tester, backend);

    // Welcome carousel (first launch).
    expect(find.text('Learn smarter'), findsOneWidget);
    await _tapText(tester, 'Get Started');

    // Create account.
    expect(find.text('Create your account'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kavi Silva');
    await tester.enterText(fields.at(1), 'kavi@gmail.com');
    await tester.enterText(fields.at(2), '77 123 4567');
    await tester.enterText(fields.at(3), 'Mito2027!');
    await _hideKeyboard(tester);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await _tapText(tester, 'Create account');

    // Check your inbox: the code autosubmits at 6 digits.
    expect(find.text('Check your inbox'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('otp-input')),
      FakeBackend.devCode,
    );
    await tester.pumpAndSettle();

    // Setup 1/3 -> 2/3 -> 3/3.
    expect(find.text('What are you studying?'), findsOneWidget);
    await _tapText(tester, 'Continue');
    expect(find.text('Set your goal'), findsOneWidget);
    await _tapText(tester, 'A');
    await _tapText(tester, 'Continue');
    expect(find.text('When can you study?'), findsOneWidget);
    for (final day in ['Mo', 'Tu', 'Th', 'Sa', 'Su']) {
      await _tapText(tester, day);
    }
    await _tapText(tester, 'Evening');
    await _tapText(tester, 'Finish setup');

    // Diagnostic.
    expect(find.text("Let's find your starting point"), findsOneWidget);
    await _tapText(tester, 'Start diagnostic');
    for (var i = 1; i <= 15; i++) {
      expect(find.text('$i/15'), findsOneWidget);
      await tester.tap(find.byType(McqOptionTile).first);
      await tester.pumpAndSettle();
      await _tapText(tester, i == 15 ? 'See my results' : 'Next');
    }

    // Result -> Home.
    expect(find.text('Your starting point'), findsOneWidget);
    await _tapText(tester, 'See my learning plan');
    expect(find.textContaining('Kavi'), findsWidgets); // "Good ..., Kavi 👋"
    expect(find.text("Today's plan"), findsOneWidget);
  });

  testWidgets('forgot password -> code -> new password -> home', (
    tester,
  ) async {
    final backend = FakeBackend(latency: const Duration(milliseconds: 50));
    await _startApp(tester, backend);

    await _tapText(tester, 'I already have an account · Log in');
    expect(find.text('Welcome back'), findsOneWidget);
    await _tapText(tester, 'Forgot password?');

    await tester.enterText(find.byType(TextFormField), 'nethmi.p@gmail.com');
    await _tapText(tester, 'Send code');
    expect(find.text('Check your inbox'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('otp-input')),
      FakeBackend.devCode,
    );
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NewPass123!');
    await tester.enterText(fields.at(1), 'NewPass123!');
    await _tapText(tester, 'Save');

    // The seeded account has finished onboarding -> Home.
    expect(find.textContaining('Nethmi'), findsWidgets);
    expect(backend.accounts['nethmi.p@gmail.com']!.password, 'NewPass123!');
  });
}
