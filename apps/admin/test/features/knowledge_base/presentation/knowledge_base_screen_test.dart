import 'package:brainbox_admin/features/knowledge_base/data/knowledge_base_repository.dart';
import 'package:brainbox_admin/features/knowledge_base/domain/knowledge_base_models.dart';
import 'package:brainbox_admin/features/knowledge_base/presentation/knowledge_base_screen.dart';
import 'package:brainbox_admin/widgets/admin_page.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Empty extends FakeKnowledgeBaseRepository {
  @override
  Future<List<ModelAnswer>> answers({ReviewStatus? status}) async => [];
}

Future<void> _pump(
  WidgetTester tester,
  FakeKnowledgeBaseRepository repo,
) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [knowledgeBaseRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: KnowledgeBaseScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('reads ModelAnswerOut and tells if it is practisable', () {
    final a = ModelAnswer.fromJson({
      'id': 'a',
      'question_id': 'q',
      'question_code': 'Q-1',
      'question_stem': 'Why?',
      'answer_text': 'Because.',
      'total_marks': 2,
      'source': 'ai',
      'status': 'approved',
      'points': [
        {
          'id': 'p',
          'text': 'Point',
          'marks': 2.0,
          'keywords': ['x'],
        },
      ],
      'updated_at': '2026-10-07T09:00:00Z',
    });
    expect(a.isPractisable, isTrue);
    expect(a.isAiWritten, isTrue);
    expect(a.withPoints(const []).isPractisable, isFalse);
  });

  test('splitKeywords trims and drops repeats like the backend', () {
    expect(splitKeywords(' ADH ,, adh, collecting   duct '), [
      'ADH',
      'collecting duct',
    ]);
  });

  test('a new answer needs a point before it is approved', () {
    const answer = NewModelAnswer(
      questionId: 'q',
      answerText: 'Text',
      approve: true,
    );
    expect(answer.problems, [
      'Add at least one marking point before approving.',
    ]);
    expect(answer.toJson()['status'], 'approved');
  });

  testWidgets('shows status and whether students can practise', (tester) async {
    await _pump(tester, FakeKnowledgeBaseRepository());

    expect(find.textContaining('Q-4830'), findsWidgets);
    expect(find.text('Students can practise'), findsNWidgets(2)); // list+detail
    expect(find.text('Not practisable'), findsOneWidget);
    expect(find.text('2 model answers · 1 practisable'), findsOneWidget);

    await tester.tap(find.textContaining('Q-4841 ·'));
    await tester.pumpAndSettle();
    expect(find.byType(AiBadge), findsOneWidget);
    expect(find.textContaining("Students can't practise"), findsOneWidget);
  });

  testWidgets('edits the keywords of the changed point only', (tester) async {
    final repo = FakeKnowledgeBaseRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Edit keywords'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Keywords for point 1'),
      'posterior pituitary, ADH',
    );
    await tester.tap(find.text('Save keywords'));
    await tester.pumpAndSettle();

    expect(repo.keywordSaves.single.$1, 'a1');
    expect(repo.keywordSaves.single.$2, {
      'p1': ['posterior pituitary', 'ADH'],
    });
    expect(find.text('ADH'), findsOneWidget); // shown as a chip
    expect(find.text('Keywords saved.'), findsOneWidget);
  });

  testWidgets('adds and approves a model answer with marking points', (
    tester,
  ) async {
    final repo = FakeKnowledgeBaseRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Add model answer'));
    await tester.pumpAndSettle();

    // Questions that already have an answer are not offered.
    await tester.tap(find.text('Question (structured or essay)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Q-4830 ·'), findsWidgets); // list behind
    await tester.tap(find.textContaining('Q-4850 ·').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Model answer'),
      'Carbon dioxide is fixed by RuBisCO...',
    );
    await tester.tap(find.text('Save and approve'));
    await tester.pumpAndSettle();
    expect(
      find.text('Add at least one marking point before approving.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Point 1'),
      'RuBisCO fixes CO2',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Keywords (comma separated)'),
      'RuBisCO, carbon fixation',
    );
    await tester.tap(find.text('Save and approve'));
    await tester.pumpAndSettle();

    final created = repo.created.single;
    expect(created.questionId, 'q4850');
    expect(created.approve, isTrue);
    expect(created.points.single.keywords, ['RuBisCO', 'carbon fixation']);
    expect(find.text('Model answer saved.'), findsOneWidget);
    expect(find.text('3 model answers · 2 practisable'), findsOneWidget);
  });

  testWidgets('empty list says how to start', (tester) async {
    await _pump(tester, _Empty());

    expect(find.text('No model answers yet'), findsOneWidget);
  });

  testWidgets('status badges use icon + word', (tester) async {
    await _pump(tester, FakeKnowledgeBaseRepository());

    final badge = tester.widget<StatusBadge>(
      find.widgetWithText(StatusBadge, 'Not practisable'),
    );
    expect(badge.showIcon, isTrue);
    expect(badge.tone, BadgeTone.danger);
  });
}
