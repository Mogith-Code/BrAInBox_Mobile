import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/home/application/home_controller.dart';
import 'package:brainbox_mobile/features/home/data/fake_home_repository.dart';
import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/home/domain/home_models.dart';
import 'package:brainbox_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

/// Fake backend signed in as the seeded "Nethmi" account.
FakeHomeRepository _figmaRepo() {
  final backend = FakeBackend(latency: Duration.zero);
  backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);
  return FakeHomeRepository(backend);
}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) =>
            HomeScreen(clock: () => DateTime(2025, 10, 7, 19, 30)),
      ),
      for (final path in [
        AppRoutes.settings,
        AppRoutes.diagnostic,
        AppRoutes.learn,
        AppRoutes.topic,
        AppRoutes.devMenu,
      ])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(body: Text('AT ${state.uri.path}')),
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

void main() {
  test('greeting by local time', () {
    expect(greetingFor(DateTime(2025, 1, 1, 5)), 'Good morning');
    expect(greetingFor(DateTime(2025, 1, 1, 11, 59)), 'Good morning');
    expect(greetingFor(DateTime(2025, 1, 1, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2025, 1, 1, 16, 59)), 'Good afternoon');
    expect(greetingFor(DateTime(2025, 1, 1, 17)), 'Good evening');
    expect(greetingFor(DateTime(2025, 1, 1, 4, 59)), 'Good evening');
  });

  group('HomeController', () {
    late _MockHomeRepository repo;
    late ProviderContainer c;
    const summary = HomeSummary(
      todaysPlan: TodaysPlan(
        total: 2,
        items: [
          PlanItem(id: 'p1', title: 'One'),
          PlanItem(id: 'p2', title: 'Two'),
        ],
      ),
    );

    setUp(() {
      repo = _MockHomeRepository();
      when(() => repo.summary()).thenAnswer((_) async => summary);
      c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [homeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final sub = c.listen(homeControllerProvider, (_, _) {});
      addTearDown(sub.close);
    });

    test('ticks a plan item right away (optimistic)', () async {
      final saved = Completer<PlanItem>();
      when(
        () => repo.setPlanItemDone('p1', done: true),
      ).thenAnswer((_) => saved.future);
      await c.read(homeControllerProvider.future);

      final pending = c
          .read(homeControllerProvider.notifier)
          .togglePlanItem('p1');
      final now = c.read(homeControllerProvider).value!.todaysPlan;
      expect(now.items.first.done, isTrue); // before the API answered
      expect(now.done, 1);

      saved.complete(const PlanItem(id: 'p1', title: 'One', done: true));
      expect(await pending, isTrue);
    });

    test('rolls back when PATCH fails', () async {
      when(
        () => repo.setPlanItemDone('p1', done: true),
      ).thenThrow(const ApiException(code: 'network', message: 'offline'));
      await c.read(homeControllerProvider.future);

      expect(
        await c.read(homeControllerProvider.notifier).togglePlanItem('p1'),
        isFalse,
      );
      final plan = c.read(homeControllerProvider).value!.todaysPlan;
      expect(plan.items.first.done, isFalse);
      expect(plan.done, 0);
    });
  });

  group('Home screen', () {
    testWidgets('data state matches the Figma dashboard', (tester) async {
      final c = ProviderContainer(
        overrides: [homeRepositoryProvider.overrideWithValue(_figmaRepo())],
      );
      addTearDown(c.dispose);
      await _pump(tester, c);
      await tester.pumpAndSettle();

      for (final text in [
        'Tuesday, 7 Oct',
        'Good evening, Nethmi 👋',
        'NP',
        '12-day streak',
        '287 days to A/L',
        'NEXT BEST ACTION',
        'AI-generated',
        'Revise: Dihybrid crosses',
        'Start 10-min revision',
        "Today's plan",
        '1/3',
        'Recap: Dihybrid crosses',
        '10 min · Unit 6',
        '62%',
        '+4% wk',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(tester.takeException(), isNull);

      // Below the fold: scroll to it like a student would.
      await tester.scrollUntilVisible(
        find.text('Continue learning'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('Nephron & osmoregulation'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Good evening, Nethmi 👋'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Ticking an item updates the count.
      await tester.tap(find.text('Practice: 10 MCQs Nephron'));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // The avatar opens Settings.
      await tester.tap(find.text('NP'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${AppRoutes.settings}'), findsOneWidget);
    });

    testWidgets('loading state shows the skeleton', (tester) async {
      final repo = _MockHomeRepository();
      when(
        () => repo.summary(),
      ).thenAnswer((_) => Completer<HomeSummary>().future);
      final c = ProviderContainer(
        overrides: [homeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await _pump(tester, c);
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('error state shows the banner with Retry', (tester) async {
      final repo = _MockHomeRepository();
      when(
        () => repo.summary(),
      ).thenThrow(const ApiException(code: 'network', message: 'offline'));
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [homeRepositoryProvider.overrideWithValue(repo)],
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

    testWidgets('after skipping, Next best action opens the diagnostic', (
      tester,
    ) async {
      final backend = FakeBackend(latency: Duration.zero);
      final account = backend.accounts['nethmi.p@gmail.com']!
        ..onboarding = const OnboardingStatus(
          profileCompleted: true,
          diagnosticSkipped: true,
        );
      backend.setSignedIn(account);
      final c = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(FakeHomeRepository(backend)),
        ],
      );
      addTearDown(c.dispose);
      await _pump(tester, c);
      await tester.pumpAndSettle();

      expect(find.text('Find your starting point'), findsOneWidget);
      expect(find.text('AI-generated'), findsNothing);
      await tester.tap(find.text('Start diagnostic'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${AppRoutes.diagnostic}'), findsOneWidget);
    });

    testWidgets('a negative weekly change is red', (tester) async {
      final repo = _MockHomeRepository();
      when(() => repo.summary()).thenAnswer(
        (_) async =>
            const HomeSummary(overallMastery: 0.5, masteryChangeWeek: -3),
      );
      final c = ProviderContainer(
        overrides: [homeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await _pump(tester, c);
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('-3% wk'));
      expect(text.style?.color, AppColors.error);
      expect(find.text('days to A/L', findRichText: true), findsNothing);
    });
  });
}
