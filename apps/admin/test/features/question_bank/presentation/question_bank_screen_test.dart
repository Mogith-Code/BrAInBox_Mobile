import 'package:brainbox_admin/app/router.dart';
import 'package:brainbox_admin/features/question_bank/data/question_bank_repository.dart';
import 'package:brainbox_admin/features/question_bank/domain/question_bank_models.dart';
import 'package:brainbox_admin/features/question_bank/presentation/edit_question_screen.dart';
import 'package:brainbox_admin/features/question_bank/presentation/question_bank_screen.dart';
import 'package:brainbox_admin/features/syllabus_manager/data/syllabus_manager_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<FakeQuestionBankRepository> _pump(
  WidgetTester tester, {
  String location = AdminRoutes.questionBank,
}) async {
  tester.view.physicalSize = const Size(1500, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeQuestionBankRepository();
  Widget page(Widget child) => Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AdminRoutes.questionBank,
        builder: (_, _) => page(const QuestionBankScreen()),
      ),
      GoRoute(
        path: AdminRoutes.questionEdit,
        builder: (_, s) => page(
          EditQuestionScreen(questionId: s.pathParameters['questionId']!),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        questionBankRepositoryProvider.overrideWithValue(repo),
        syllabusManagerRepositoryProvider.overrideWithValue(
          FakeSyllabusManagerRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('QuestionDetail.problems', () {
    test('a blank question lists what is missing', () {
      expect(QuestionDetail.blank().problems, [
        'Write the question stem.',
        'Pick the topic.',
        'Mark exactly one correct answer.',
        'Fill in every option.',
        'Every wrong option needs a misconception.',
      ]);
    });
  });

  testWidgets('lists questions with counts, sources and statuses', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('8,942 questions · 41% from past papers'), findsOneWidget);
    expect(find.text('Q-4821'), findsOneWidget);
    expect(find.text('2019 paper'), findsOneWidget);
    expect(find.text('AI-generated · pending review'), findsNWidgets(2));
    expect(find.text('Showing 1–7 of 8,942'), findsOneWidget);
  });

  testWidgets('select rows and approve them in bulk', (tester) async {
    await _pump(tester);

    await tester.tap(find.byType(Checkbox).at(2)); // Q-4822
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Approve: done.'), findsOneWidget);
    expect(find.text('AI-generated · pending review'), findsOneWidget);
  });

  testWidgets('editor shows options, misconceptions and the preview', (
    tester,
  ) async {
    await _pump(tester, location: AdminRoutes.questionEditPath('q4822'));

    expect(find.text('Edit question · Q-4822'), findsOneWidget);
    expect(find.text('Correct answer'), findsOneWidget);
    expect(find.text('06 Genetics'), findsOneWidget); // mapping
    expect(find.text('6.2 Deviations from Mendel'), findsOneWidget);
    expect(find.textContaining('Likely misconception'), findsOneWidget);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Published.'), findsOneWidget);
  });

  testWidgets('a new question cannot be published empty', (tester) async {
    await _pump(tester, location: AdminRoutes.questionEditPath('new'));

    expect(find.text('New question'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pump();
    expect(find.text('Write the question stem.'), findsOneWidget);
  });
}
