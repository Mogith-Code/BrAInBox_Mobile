import 'package:brainbox_admin/features/past_papers/data/past_papers_repository.dart';
import 'package:brainbox_admin/features/past_papers/domain/past_papers_models.dart';
import 'package:brainbox_admin/features/past_papers/presentation/past_papers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakePastPapersRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakePastPapersRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pastPapersRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: PastPapersScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads the paper type and extraction status', () {
    final paper = PastPaper.fromJson({
      'id': 'p',
      'year': 2019,
      'paper_type': 'paper_2_structured',
      'extraction': 'low_confidence',
      'low_confidence': 3,
    });
    expect(paper.paperType, PaperType.paper2Structured);
    expect(paper.extraction, ExtractionStatus.lowConfidence);
  });

  testWidgets('shows papers with their extraction state', (tester) async {
    await _pump(tester);

    expect(find.text('Past papers & marking schemes'), findsOneWidget);
    expect(find.text('✓ 48 questions extracted'), findsNWidgets(4));
    expect(find.text('Extracting · 68%'), findsOneWidget);
    expect(find.text('⚠ 3 low-confidence'), findsOneWidget);
    expect(find.text('+ Link scheme'), findsOneWidget);
    expect(find.text('Outdated syllabus'), findsOneWidget);
  });

  testWidgets('open a paper, add a suggested keyword and save', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Open').at(4)); // 2019 Paper II
    await tester.pumpAndSettle();
    expect(find.textContaining('Q3 (b)'), findsOneWidget);
    expect(find.textContaining('OCR 94%'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'osmoreceptors'));
    await tester.pump();
    await tester.tap(find.text('Save & next question'));
    await tester.pumpAndSettle();

    final saved = (await repo.questions('p5')).first;
    expect(saved.keywords, contains('osmoreceptors'));
    expect(find.textContaining('Q3 (c)'), findsOneWidget); // moved on
  });
}
