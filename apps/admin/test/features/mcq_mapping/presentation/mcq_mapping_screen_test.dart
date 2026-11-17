import 'package:brainbox_admin/app/router.dart';
import 'package:brainbox_admin/features/mcq_mapping/data/mcq_mapping_repository.dart';
import 'package:brainbox_admin/features/mcq_mapping/domain/mcq_mapping_models.dart';
import 'package:brainbox_admin/features/mcq_mapping/presentation/mcq_mapping_screen.dart';
import 'package:brainbox_admin/features/question_bank/data/question_bank_repository.dart';
import 'package:brainbox_admin/features/syllabus_manager/data/syllabus_manager_repository.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Bank extends FakeQuestionBankRepository {
  final saved = <QuestionDetail>[];

  @override
  Future<QuestionDetail> save(QuestionDetail question) {
    saved.add(question);
    return super.save(question);
  }
}

Future<(_Bank, FakeMcqMappingRepository)> _pump(
  WidgetTester tester, {
  String location = AdminRoutes.mcqMapping,
}) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bank = _Bank();
  final mapping = FakeMcqMappingRepository();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AdminRoutes.mcqMapping,
        builder: (_, s) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: McqMappingScreen(
              questionId: s.uri.queryParameters['questionId'],
            ),
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        questionBankRepositoryProvider.overrideWithValue(bank),
        mcqMappingRepositoryProvider.overrideWithValue(mapping),
        syllabusManagerRepositoryProvider.overrideWithValue(
          FakeSyllabusManagerRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (bank, mapping);
}

TextField _field(WidgetTester tester, String hint) => tester.widget<TextField>(
  find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint,
  ),
);

void main() {
  test('reads a MisconceptionSuggestion', () {
    final s = MisconceptionSuggestion.fromJson({
      'option_id': 'o1',
      'label': 'B',
      'option_text': '1:1',
      'current_misconception': null,
      'suggested_misconception': 'Ignores linkage',
      'misconception_id': null,
      'is_new': true,
      'similarity': null,
    });
    expect(s.label, 'B');
    expect(s.isNew, isTrue);
    expect(s.isUnchanged, isFalse);
  });

  test('the editor always has options A-E', () {
    final q = withFiveOptions(
      const QuestionDetail(
        options: [OptionDraft(label: 'B', text: 'x')],
      ),
    );
    expect([for (final o in q.options) o.label], ['A', 'B', 'C', 'D', 'E']);
    expect(q.options[1].text, 'x');
  });

  testWidgets('lists MCQs and opens one', (tester) async {
    await _pump(tester);

    expect(find.text('Pick an MCQ'), findsOneWidget);
    // Only MCQs: the structured and essay rows of the fake bank are left out.
    expect(find.textContaining('ADH in water'), findsNothing);

    await tester.tap(find.textContaining('dihybrid test cross'));
    await tester.pumpAndSettle();

    expect(find.text('MCQ · Q-4822'), findsOneWidget);
    expect(find.byType(McqOptionTile), findsNWidgets(5));
    expect(find.text('Correct answer'), findsOneWidget);
  });

  testWidgets('AI suggestions are saved only when accepted', (tester) async {
    final (_, mapping) = await _pump(
      tester,
      location: AdminRoutes.mcqMappingPath('q4822'),
    );

    await tester.tap(find.text('Suggest with AI'));
    await tester.pumpAndSettle();

    expect(find.text('Same as now'), findsOneWidget); // option A
    expect(find.text('New misconception'), findsOneWidget);
    expect(find.text('Already in the bank · 88% match'), findsOneWidget);
    expect(mapping.confirmed, isEmpty);

    await tester.tap(find.text('Dismiss').last); // option E
    await tester.pumpAndSettle();
    expect(find.text('Dismissed'), findsOneWidget);

    await tester.tap(find.text('Accept for B'));
    await tester.pumpAndSettle();

    expect(mapping.confirmed, [
      ('opt-b', 'Treats a test cross of linked genes like unlinked genes'),
    ]);
    expect(find.text('Accepted · saved'), findsOneWidget);
    expect(
      _field(tester, 'Misconception for B').controller!.text,
      'Treats a test cross of linked genes like unlinked genes',
    );
    // Already saved on the server, so nothing is waiting to be saved.
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('asks to save first when there are unsaved changes', (
    tester,
  ) async {
    final (bank, _) = await _pump(
      tester,
      location: AdminRoutes.mcqMappingPath('q4822'),
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.hintText == 'Misconception for D',
      ),
      'Uses the monohybrid ratio',
    );
    await tester.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Suggest with AI'));
    await tester.pump();
    expect(
      find.text('Save your changes first, so the AI sees them.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = bank.saved.single;
    expect(saved.status, 'pending_review'); // status is kept
    expect(
      saved.options.firstWhere((o) => o.label == 'D').misconception,
      'Uses the monohybrid ratio',
    );
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('the student preview shows the feedback for a pick', (
    tester,
  ) async {
    await _pump(tester, location: AdminRoutes.mcqMappingPath('q4822'));

    await tester.tap(find.widgetWithText(McqOptionTile, '3 : 1'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Likely misconception: Applies monohybrid ratio to dihybrid cross',
      ),
      findsOneWidget,
    );
    final wrong = tester.widget<McqOptionTile>(
      find.widgetWithText(McqOptionTile, '3 : 1'),
    );
    expect(wrong.state, McqOptionState.wrong);
  });
}
