import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:brainbox_mobile/features/profile/domain/profile_models.dart';
import 'package:brainbox_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_app.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.profileSetup,
    routes: [
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostic,
        builder: (_, _) => const Scaffold(body: Text('DIAGNOSTIC')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

/// A fake backend with a signed-in, verified student who has no profile.
Future<ProviderContainer> _newStudent(WidgetTester tester) async {
  final backend = FakeBackend(latency: Duration.zero);
  final c = fakeContainer(backend: backend);
  addTearDown(c.dispose);
  await tester.runAsync(() async {
    final auth = c.read(authRepositoryProvider);
    await auth.signUp(
      fullName: 'Kavi Silva',
      email: 'kavi@gmail.com',
      password: 'Mito2027',
    );
    backend.signedIn!
      ..emailVerified = true
      ..registered = true;
  });
  return c;
}

void main() {
  testWidgets('loading state', (tester) async {
    final repo = _MockProfileRepository();
    when(
      () => repo.options(),
    ).thenAnswer((_) => Completer<ProfileOptions>().future);
    when(() => repo.profile()).thenAnswer((_) => Completer<Profile>().future);
    final c = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await _pump(tester, c);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state with Retry', (tester) async {
    final repo = _MockProfileRepository();
    when(
      () => repo.options(),
    ).thenThrow(const ApiException(code: 'network', message: 'offline'));
    when(() => repo.profile()).thenAnswer((_) async => const Profile());
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await _pump(tester, c);
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Check it and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('walks through the 3 steps', (tester) async {
    final c = await _newStudent(tester);
    await _pump(tester, c);
    await tester.pumpAndSettle();

    // Step 1
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('What are you studying?'), findsOneWidget);
    expect(find.text('Biological Science'), findsOneWidget);
    expect(find.text('Biology'), findsOneWidget);
    expect(find.text('10 units · 2025 syllabus'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Set your goal'), findsOneWidget);
    expect(find.text('Okay-ish'), findsOneWidget); // confidence 50
    expect(find.text('How confident do you feel in Biology?'), findsOneWidget);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('When can you study?'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
    for (final day in ['Mo', 'Tu', 'Th', 'Sa', 'Su']) {
      await tester.tap(find.text(day));
      await tester.pump(); // one tap per frame, like a real finger
    }
    await tester.pump();
    expect(find.text('≈ 10 hours a week · a steady pace'), findsOneWidget);
    await tester.tap(find.text('Evening'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Back keeps the values.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('≈ 10 hours a week · a steady pace'), findsOneWidget);

    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    expect(find.text('DIAGNOSTIC'), findsOneWidget);
    final backend = c.read(fakeBackendProvider);
    expect(backend.signedIn!.onboarding.profileCompleted, isTrue);
    expect(backend.signedIn!.profile['study_days'], [
      'mon',
      'tue',
      'thu',
      'sat',
      'sun',
    ]);
  });
}
