import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_summary.dart';
import 'package:brainbox_mobile/features/insights/presentation/insights_screen.dart';
import 'package:brainbox_mobile/features/insights/presentation/widgets/insights_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../insights_fixtures.dart';
import '../insights_test_app.dart';

void main() {
  group('InsightsScreen', () {
    testWidgets('shows the loaded overview', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      // Mastery ring and legend (from /insights/summary).
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('mastery'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('11 topics'), findsOneWidget);
      expect(find.text('19 topics'), findsOneWidget);

      // Study time.
      expect(find.text('Study time'), findsOneWidget);
      expect(find.text('13.7h this week'), findsOneWidget);
      expect(find.text('3.1h'), findsOneWidget);
      expect(find.bySemanticsLabel('W: 0.5h'), findsOneWidget);

      // Accuracy trend: the null week is a gap, the change is the backend's.
      expect(find.text('Accuracy trend'), findsOneWidget);
      expect(find.text('+22% in 8 wks'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('W3: not attempted')),
        findsOneWidget,
      );

      // Unit mastery: "—" for a unit with nothing attempted, never 0 %.
      expect(find.text('1. Introduction to biology'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('7. Molecular biology'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      // The per-attempt hero card is not on the overview.
      expect(find.text('21 correct of 34 attempted'), findsNothing);
      expect(find.text('Credit Pass'), findsOneWidget); // grade legend only

      // Strongest / weakest.
      expect(find.text('Strongest'), findsOneWidget);
      expect(find.text('Enzymes'), findsOneWidget);
      expect(find.text('Weakest'), findsOneWidget);

      // Weak topics, legend and note.
      expect(find.text('Weak topics'), findsOneWidget);
      expect(find.text('Photosynthesis'), findsOneWidget);
      expect(find.text('Open mastery map'), findsOneWidget);
      expect(find.text('75% and above'), findsOneWidget);
      expect(find.text('Formative feedback'), findsOneWidget);
      expect(find.textContaining('not official examination'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('renders in the dark theme', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(json: sampleInsightsJson()),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Unit mastery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('summary cards say "Coming soon" until the backend has '
        '/insights/summary; the ring falls back to topic statuses', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(
          json: sampleInsightsJson(),
          summaryError: const InsightsNotAvailableYet(),
        ),
      );

      // Ring: overall percent and status counts from /insights/topics.
      expect(find.text('62%'), findsOneWidget);
      expect(find.bySemanticsLabel('Mastered: 1 topic'), findsOneWidget);
      expect(find.bySemanticsLabel('Improving: 1 topic'), findsOneWidget);
      expect(find.bySemanticsLabel('Weak: 2 topics'), findsOneWidget);

      // Study time, trend and units: no invented numbers.
      expect(find.text('Coming soon'), findsNWidgets(3));
      expect(find.textContaining('this week'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('summary cards show empty states without data', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(
          json: sampleInsightsJson(),
          summaryJson: quietSummaryJson(),
        ),
      );

      expect(find.text('No study time recorded this week.'), findsOneWidget);
      expect(find.textContaining('to see a trend'), findsOneWidget);
      expect(find.text('No units attempted yet.'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('a summary server error shows Retry inside the cards', (
      tester,
    ) async {
      final repository = fakeRepository(
        json: sampleInsightsJson(),
        summaryError: const InsightsServerError('Server error'),
      );
      await pumpInsights(tester, const InsightsScreen(), repository);

      expect(find.text("Couldn't load this"), findsNWidgets(3));
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();

      verify(
        () => repository.fetchSummary(period: InsightsPeriod.week),
      ).called(2);
    });

    testWidgets('changing the period loads that period', (tester) async {
      final repository = fakeRepository(json: sampleInsightsJson());
      await pumpInsights(tester, const InsightsScreen(), repository);

      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This month').last);
      await tester.pumpAndSettle();

      verify(
        () => repository.fetchSummary(period: InsightsPeriod.month),
      ).called(1);
      expect(find.text('This month'), findsOneWidget);
    });

    testWidgets('single-attempt mode never requests the summary', (
      tester,
    ) async {
      final repository = fakeRepository(json: sampleInsightsJson());
      await pumpInsights(
        tester,
        const InsightsScreen(attemptId: 'a-1'),
        repository,
      );

      expect(find.text('21 correct of 34 attempted'), findsOneWidget);
      expect(find.text('This week'), findsNothing);
      verifyNever(() => repository.fetchSummary(period: any(named: 'period')));
    });

    testWidgets('shows skeleton cards while loading', (tester) async {
      final repository = MockInsightsRepository();
      final pending = Completer<TopicInsights>();
      when(
        () => repository.fetchTopicInsights(attemptId: any(named: 'attemptId')),
      ).thenAnswer((_) => pending.future);
      stubSummary(repository);

      await pumpInsights(
        tester,
        const InsightsScreen(),
        repository,
        settle: false,
      );
      await tester.pump();

      expect(find.byType(InsightsSkeleton), findsOneWidget);
    });

    testWidgets('shows the empty state when nothing was attempted', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(json: emptyInsightsJson()),
      );

      expect(find.text('No results yet'), findsOneWidget);
      expect(
        find.text('Finish a quiz to see your topic scores.'),
        findsOneWidget,
      );
      expect(find.text('Go to Practice'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('lists topics without enough data, collapsed', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(json: insufficientOnlyJson()),
      );

      expect(find.text('Not enough data yet (1)'), findsOneWidget);
      expect(find.text('Needs 3 more questions'), findsNothing);

      await tester.tap(find.text('Not enough data yet (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Sex linkage'), findsOneWidget);
      expect(find.text('Needs 3 more questions'), findsOneWidget);
    });

    testWidgets('shows the offline state and retries', (tester) async {
      final repository = fakeRepository(
        error: const InsightsOffline('Cannot reach the server.'),
      );
      await pumpInsights(tester, const InsightsScreen(), repository);

      expect(find.text("You're offline"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(() => repository.fetchTopicInsights()).called(2);
    });

    testWidgets('shows the error banner for a server error', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(),
        fakeRepository(error: const InsightsServerError('Server error')),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('single-attempt mode shows "This attempt"', (tester) async {
      final repository = fakeRepository(json: sampleInsightsJson());
      await pumpInsights(
        tester,
        const InsightsScreen(attemptId: 'a-1'),
        repository,
      );

      expect(find.text('This attempt'), findsOneWidget);
      expect(find.text('2 unanswered · From this attempt'), findsOneWidget);
      verify(() => repository.fetchTopicInsights(attemptId: 'a-1')).called(1);
    });

    testWidgets('an unavailable attempt shows a back button', (tester) async {
      await pumpInsights(
        tester,
        const InsightsScreen(attemptId: 'someone-else'),
        fakeRepository(error: const InsightsUnavailable()),
      );

      expect(find.text("This result isn't available"), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('reads attempt_id from the route and goes to profile setup '
        'when not registered', (tester) async {
      final repository = fakeRepository(error: const InsightsNotRegistered());
      final router = GoRouter(
        initialLocation: '${AppRoutes.insights}?attempt_id=a-9',
        routes: [
          GoRoute(
            path: AppRoutes.insights,
            builder: (_, _) => const InsightsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileSetup,
            builder: (_, _) => const Text('Profile setup page'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.fetchTopicInsights(attemptId: 'a-9')).called(1);
      expect(find.text('Profile setup page'), findsOneWidget);
    });
  });
}
