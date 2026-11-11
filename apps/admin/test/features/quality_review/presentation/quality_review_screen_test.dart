import 'package:brainbox_admin/features/quality_review/data/quality_review_repository.dart';
import 'package:brainbox_admin/features/quality_review/domain/quality_review_models.dart';
import 'package:brainbox_admin/features/quality_review/presentation/quality_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qualityReviewRepositoryProvider.overrideWithValue(
          FakeQualityReviewRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: QualityReviewScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('allPass and the report total', () {
    const item = QualityItem(
      id: 'q',
      code: 'Q',
      stem: 's',
      checks: [
        QualityCheck(name: 'a'),
        QualityCheck(name: 'b', result: CheckResult.fail),
      ],
      studentReports: [
        StudentReportCount(text: 'x', count: 3),
        StudentReportCount(text: 'y'),
      ],
    );
    expect(item.allPass, isFalse);
    expect(item.reportTotal, 4);
    expect(item.result('b'), CheckResult.fail);
    expect(item.result('zzz'), isNull);
  });

  testWidgets('shows the numbers and opens the failing question', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Question quality review'), findsOneWidget);
    expect(find.text('Approve all passing (2)'), findsOneWidget);
    expect(find.text('1h 40m'), findsOneWidget);
    // The first failing item is shown in the detail panel.
    expect(find.textContaining('PCT and descending limb'), findsOneWidget);
    expect(find.text('4 student reports'), findsOneWidget);
  });

  testWidgets('Approve all passing empties those rows', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Approve all passing (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Approved 2 questions.'), findsOneWidget);
    expect(find.text('Approve all passing (0)'), findsOneWidget);
  });
}
