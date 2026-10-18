import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/practice/data/diagnostic_repository.dart';
import 'package:brainbox_mobile/features/practice/domain/diagnostic_models.dart';
import 'package:brainbox_mobile/features/practice/presentation/diagnostic_question_screen.dart';
import 'package:brainbox_mobile/features/practice/presentation/diagnostic_result_screen.dart';
import 'package:brainbox_mobile/features/practice/presentation/diagnostic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_app.dart';

class _MockRepo extends Mock implements DiagnosticRepository {}

/// A fake backend with a signed-in student whose profile is done.
Future<ProviderContainer> _student(WidgetTester tester) async {
  final backend = FakeBackend(latency: Duration.zero);
  final c = fakeContainer(backend: backend);
  addTearDown(c.dispose);
  await tester.runAsync(() async {
    await c
        .read(authRepositoryProvider)
        .signUp(
          fullName: 'Kavi Silva',
          email: 'kavi@gmail.com',
          password: 'Mito2027',
        );
    backend.signedIn!
      ..emailVerified = true
      ..registered = true
      ..onboarding = const OnboardingStatus(profileCompleted: true);
  });
  return c;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer c, {
  String initial = AppRoutes.diagnostic,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.diagnostic,
        builder: (_, _) => const DiagnosticIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnosticQuestions,
        builder: (_, _) => const DiagnosticQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnosticResult,
        builder: (_, _) => const DiagnosticResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('HOME')),
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
  testWidgets('intro shows the Figma content', (tester) async {
    final c = await _student(tester);
    await _pump(tester, c);
    for (final text in [
      "Let's find your starting point",
      'Adaptive',
      '15',
      'quick MCQs',
      '~10',
      'minutes',
      'units',
      'Start diagnostic',
      'Skip for now',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('full run: 15 questions, then the result', (tester) async {
    final c = await _student(tester);
    await _pump(tester, c);
    await tester.tap(find.text('Start diagnostic'));
    await tester.pumpAndSettle();

    for (var i = 1; i <= 15; i++) {
      expect(find.text('$i/15'), findsOneWidget);
      // Next is disabled until an option is picked.
      await tester.tap(find.byType(McqOptionTile).first);
      await tester.pump();
      await tester.tap(find.text(i == 15 ? 'See my results' : 'Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Your starting point'), findsOneWidget);
    expect(find.text('Your strongest'), findsOneWidget);
    expect(find.text('Unit 4'), findsOneWidget);
    expect(find.text('Needs work'), findsOneWidget);
    expect(find.text('Genetics'), findsWidgets);
    expect(find.text('Mastery by unit'), findsOneWidget);
    expect(find.text('AI-generated'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(
      find.text(
        'Formative feedback — not an official exam mark.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      c.read(fakeBackendProvider).signedIn!.onboarding.diagnosticCompleted,
      isTrue,
    );

    await tester.tap(find.text('See my learning plan'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Skip for now goes home and marks it skipped', (tester) async {
    final c = await _student(tester);
    await _pump(tester, c);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(
      c.read(fakeBackendProvider).signedIn!.onboarding.diagnosticSkipped,
      isTrue,
    );
  });

  testWidgets('NOT_ENOUGH_QUESTIONS shows the empty state', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.start(),
    ).thenThrow(const ApiException(code: 'NOT_ENOUGH_QUESTIONS', message: 'm'));
    final c = ProviderContainer(
      overrides: [diagnosticRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await _pump(tester, c);
    await tester.tap(find.text('Start diagnostic'));
    await tester.pumpAndSettle();
    expect(find.text("We're still adding questions"), findsOneWidget);
    expect(find.text('You can start learning now.'), findsOneWidget);
  });

  testWidgets('result screen: loading and error states', (tester) async {
    final repo = _MockRepo();
    final completer = Completer<DiagnosticResult>();
    when(() => repo.result()).thenAnswer((_) => completer.future);
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [diagnosticRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: DiagnosticResultScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(
      const ApiException(code: 'DIAGNOSTIC_NOT_FOUND', message: 'm'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't find your diagnostic result."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
