import 'package:brainbox_admin/features/analytics/data/analytics_repository.dart';
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

Future<_Recorder> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Recorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
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
}
