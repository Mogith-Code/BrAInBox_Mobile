import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/presentation/heatmap_screen.dart';
import 'package:brainbox_mobile/features/insights/presentation/widgets/heatmap_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../insights_fixtures.dart';
import '../insights_test_app.dart';

/// [screen] inside a GoRouter, with a quiz-setup route that prints its URI.
Future<void> _pumpWithRouter(
  WidgetTester tester,
  Widget screen,
  InsightsRepository repository,
) async {
  tester.view.physicalSize = const Size(420, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.heatmap,
    routes: [
      GoRoute(path: AppRoutes.heatmap, builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.quizSetup,
        builder: (_, s) => Scaffold(body: Text('AT ${s.uri}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HeatmapScreen (GET /insights/heatmap)', () {
    testWidgets('shows one row per unit and one cell per topic', (
      tester,
    ) async {
      final repository = fakeRepository(json: sampleInsightsJson());
      await pumpInsights(tester, const HeatmapScreen(), repository);

      expect(find.text('Mastery map'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('1 Introduction to Biology'), findsOneWidget);
      expect(find.text('6 Genetics'), findsOneWidget);
      expect(find.byType(TopicHeatCell), findsNWidgets(4));
      expect(find.text('82'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);
      // Not practised shows a dash, never 0.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      // The topics endpoint is not used for the overall map.
      verifyNever(
        () => repository.fetchTopicInsights(attemptId: any(named: 'attemptId')),
      );
    });

    testWidgets('cells have a spoken label with the level', (tester) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(
        find.bySemanticsLabel(
          '6.2 Deviations from Mendel, 23 percent, weak. Practise this topic',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          '1.2 Life processes, not practised, not started. '
          'Practise this topic',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping a topic opens quiz setup for it', (tester) async {
      await _pumpWithRouter(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      await tester.tap(find.text('6.3'));
      await tester.pumpAndSettle();

      expect(
        find.text('AT ${AppRoutes.quizSetupPath(topicId: 't-6-3')}'),
        findsOneWidget,
      );
    });

    testWidgets('a new student still sees the map and how to start', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(
          json: sampleInsightsJson(),
          heatmapJson: {
            'units': [
              {
                'unit_id': 'u-1',
                'number': 1,
                'title': 'Introduction to Biology',
                'topics': [
                  {
                    'topic_id': 't-1',
                    'number': '1.1',
                    'title': 'Nature of biology',
                    'mastery': null,
                    'level': 'not_started',
                    'concepts_practised': 0,
                    'concepts_total': 3,
                  },
                ],
              },
            ],
          },
        ),
      );

      expect(find.textContaining('Nothing practised yet'), findsOneWidget);
      expect(find.byType(TopicHeatCell), findsOneWidget);
    });

    testWidgets('shows the empty state without topics', (tester) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson(), heatmapJson: {'units': []}),
      );

      expect(find.text('No topics yet'), findsOneWidget);
    });

    testWidgets('shows the error with Retry', (tester) async {
      final repository = fakeRepository(
        json: sampleInsightsJson(),
        heatmapError: const InsightsServerError('Server error'),
      );
      await pumpInsights(tester, const HeatmapScreen(), repository);

      expect(find.byType(ErrorBanner), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      verify(repository.fetchHeatmap).called(2);
    });
  });

  group('HeatmapScreen (one attempt)', () {
    const screen = HeatmapScreen(attemptId: 'a-1');

    testWidgets('shows one row per unit and one cell per topic', (
      tester,
    ) async {
      final repository = fakeRepository(json: sampleInsightsJson());
      await pumpInsights(tester, screen, repository);

      expect(find.text('Mastery map · This attempt'), findsOneWidget);
      expect(find.byType(HeatmapCell), findsNWidgets(7));
      expect(find.text('22'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      final labels = [
        for (final view in tester.widgetList<MasteryMapRowView>(
          find.byType(MasteryMapRowView),
        ))
          view.row.label,
      ];
      expect(labels, [
        '1 Cell biology',
        '3 Plant biology',
        '6 Genetics',
        'Other',
      ]);
      verifyNever(repository.fetchHeatmap);
    });

    testWidgets('cells have a spoken label', (tester) async {
      await pumpInsights(
        tester,
        screen,
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(
        find.bySemanticsLabel('Dihybrid crosses, 22 percent, very weak'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Cell structure, not attempted, not attempted'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a cell opens the topic sheet and Open topic', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        screen,
        fakeRepository(json: sampleInsightsJson()),
      );

      await tester.tap(
        find.bySemanticsLabel('Dihybrid crosses, 22 percent, very weak'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TopicSheet), findsOneWidget);
      expect(find.text('Unit 6 Genetics'), findsOneWidget);
      expect(find.text('9 questions tried'), findsOneWidget);
      final cell = tester.widget<HeatmapCell>(
        find.ancestor(of: find.text('22'), matching: find.byType(HeatmapCell)),
      );
      expect(cell.selected, isTrue);
      expect(find.text('Practice'), findsOneWidget);

      await tester.tap(find.text('Open topic'));
      await tester.pumpAndSettle();

      expect(find.text('Topic result'), findsOneWidget);
      expect(find.text('What this means'), findsOneWidget);
    });

    testWidgets('Practice on the sheet opens quiz setup for the topic', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        screen,
        fakeRepository(json: sampleInsightsJson()),
      );

      await tester.tap(
        find.bySemanticsLabel('Dihybrid crosses, 22 percent, very weak'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      expect(
        find.text('AT ${AppRoutes.quizSetupPath(topicId: 't-dihybrid')}'),
        findsOneWidget,
      );
    });

    testWidgets('shows the empty state', (tester) async {
      await pumpInsights(
        tester,
        screen,
        fakeRepository(json: emptyInsightsJson()),
      );

      expect(find.text('No results yet'), findsOneWidget);
    });

    testWidgets('shows the error with Retry', (tester) async {
      await pumpInsights(
        tester,
        screen,
        fakeRepository(error: const InsightsServerError('Server error')),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
