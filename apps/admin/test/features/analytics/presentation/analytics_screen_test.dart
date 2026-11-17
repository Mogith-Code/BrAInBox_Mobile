import 'package:brainbox_admin/features/analytics/data/analytics_repository.dart';
import 'package:brainbox_admin/features/analytics/data/evaluations_repository.dart';
import 'package:brainbox_admin/features/analytics/domain/evaluation_models.dart';
import 'package:brainbox_admin/features/analytics/domain/analytics_models.dart';
import 'package:brainbox_admin/features/analytics/presentation/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder extends FakeAnalyticsRepository {
  final days = <int>[];

  @override
  Future<AnalyticsData> load(int days) {
    this.days.add(days);
    return super.load(days);
  }
}

Future<_Recorder> _pump(
  WidgetTester tester, {
  EvaluationsRepository? evaluations,
}) async {
  tester.view.physicalSize = const Size(1500, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Recorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(repo),
        evaluationsRepositoryProvider.overrideWithValue(
          evaluations ?? FakeEvaluationsRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: AnalyticsScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads the backend analytics JSON', () {
    final ai = AnalyticsAiUsage.fromJson({
      'days': 30,
      'since': '2026-10-01',
      'total_requests': 10,
      'images': 2,
      'total_cost_usd': null,
      'by_feature': [
        {'feature': 'visuals', 'requests': 4, 'percent': 40.0},
      ],
      'daily_requests': [
        {'day': '2026-10-01', 'count': 3},
      ],
    });
    expect(ai.byFeature.single.feature, 'visuals');
    expect(ai.dailyRequests.single.count, 3);

    final unit = UnitAverage.fromJson({
      'unit_id': 'u',
      'number': 9,
      'title': 'Microbes',
      'average_mastery': null,
      'students_assessed': 0,
    });
    expect(unit.averageMastery, isNull);
  });

  testWidgets('shows usage, AI features, mastery and misconceptions', (
    tester,
  ) async {
    final repo = await _pump(tester);

    expect(repo.days, [30]); // the backend default
    expect(find.text('↗ +22% vs before'), findsOneWidget);
    expect(find.text('Visual generator'), findsOneWidget);
    expect(find.text('48,210 AI requests · 2,310 images'), findsOneWidget);
    expect(find.text('41% ⚠'), findsOneWidget); // Genetics
    expect(find.text('Not assessed yet'), findsOneWidget); // never 0 %
    expect(find.text('Linked genes assorting independently'), findsOneWidget);
  });

  testWidgets('switching to 7d reloads with days=7', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();

    expect(repo.days, [30, 7]);
  });

  test('reads the evaluation JSON; nulls stay null', () {
    final report = AccuracyReport.fromJson({
      'samples': 0,
      'mean_absolute_error': null,
      'within_one_mark': null,
      'correlation': null,
      'note': 'No teacher marks yet.',
    });
    expect(report.meanAbsoluteError, isNull);
    final page = EvaluationPage.fromJson({
      'items': [
        {
          'id': 'e',
          'question': 'Q',
          'answer_text': null,
          'estimated_marks': 4,
          'max_marks': 8,
          'manual_marks': null,
          'difference': null,
          'created_at': '2026-10-07T09:00:00Z',
        },
      ],
      'total': 1,
      'page': 1,
      'size': 20,
      'pages': 1,
    });
    expect(page.items.single.estimatedMarks, 4);
    expect(page.items.single.manualMarks, isNull);
    expect(const EvaluationQuery(onlyManual: true).toQuery(), {
      'page': 1,
      'size': 10,
      'only_manual': true,
    });
    expect(MarkGap.of(-1), MarkGap.close);
    expect(MarkGap.of(2.5), MarkGap.higher);
    expect(MarkGap.of(null), isNull);
  });

  testWidgets('shows evaluation accuracy and the evaluations', (tester) async {
    await _pump(tester);

    expect(find.text('50%'), findsOneWidget); // within 1 mark
    expect(find.text('2.0 marks'), findsOneWidget);
    expect(find.text('Poor · AI marks need review'), findsOneWidget);
    expect(find.text('AI higher by 3'), findsOneWidget);
    expect(find.text('Not compared'), findsOneWidget);
  });

  testWidgets('saves a teacher mark and refreshes accuracy', (tester) async {
    final repo = FakeEvaluationsRepository();
    await _pump(tester, evaluations: repo);

    final row = find.byKey(const ValueKey('e3'));
    final box = find.descendant(of: row, matching: find.byType(TextField));
    final save = find.descendant(of: row, matching: find.text('Save'));

    await tester.enterText(box, '9');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Enter 0 to 8.'), findsOneWidget);

    await tester.enterText(box, '7');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Teacher marks saved.'), findsOneWidget);
    expect(find.text('AI lower by 2'), findsOneWidget);
    expect(find.text('Not compared'), findsNothing);
    expect(find.text('33%'), findsOneWidget); // 1 of 3 within a mark
  });

  testWidgets('no teacher marks yet shows an empty state, not 0%', (
    tester,
  ) async {
    await _pump(tester, evaluations: _NoMarks());

    expect(find.text('No teacher marks yet'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });
}

class _NoMarks extends FakeEvaluationsRepository {
  @override
  Future<AccuracyReport> accuracy() async => const AccuracyReport();
}
