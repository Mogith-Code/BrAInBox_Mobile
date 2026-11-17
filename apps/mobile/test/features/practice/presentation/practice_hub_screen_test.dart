import 'package:brainbox_mobile/features/practice/data/practice_repository.dart';
import 'package:brainbox_mobile/features/practice/domain/practice_models.dart';
import 'package:brainbox_mobile/features/practice/presentation/practice_hub_screen.dart';
import 'package:brainbox_mobile/features/practice/presentation/widgets/answer_feedback_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements PracticeRepository {}

void main() {
  Future<void> pumpHub(WidgetTester tester, PracticeRepository repository) {
    // A tall screen, so every tile of the list is built.
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [practiceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PracticeHubScreen()),
      ),
    );
  }

  testWidgets('shows the quiz in progress, mistakes and recent results', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(repository.fetchHub).thenAnswer(
      (_) async => const PracticeHub(
        inProgress: QuizBrief(
          quizId: 'q1',
          title: 'Quiz: Genetics',
          status: 'in_progress',
          total: 10,
        ),
        recent: [
          QuizBrief(
            quizId: 'q0',
            title: 'Mixed quiz',
            status: 'graded',
            total: 10,
            score: 7,
            percent: 70,
          ),
        ],
        openMistakes: 3,
        weakConcepts: 2,
      ),
    );

    await pumpHub(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Quiz: Genetics'), findsOneWidget);
    expect(find.text('Resume quiz (10 questions)'), findsOneWidget);
    expect(find.text('3 questions you got wrong'), findsOneWidget);
    expect(find.text('2 weak concepts to work on'), findsOneWidget);
    expect(find.text('7 of 10 correct'), findsOneWidget);
  });

  testWidgets('keeps the practice options when the overview fails', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(repository.fetchHub).thenThrow(Exception('offline'));

    await pumpHub(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Topic quiz'), findsOneWidget);
  });

  testWidgets('feedback card explains a wrong answer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnswerFeedbackCard(
              feedback: AnswerFeedback(
                questionId: 'q',
                selectedOptionId: 'c',
                correctOptionId: 'b',
                isCorrect: false,
                explanation: 'Active transport needs ATP.',
                misconception: MisconceptionCard(
                  title: 'Confuses active transport with diffusion',
                ),
                masteryBefore: 50,
                masteryAfter: 35,
                recurring: true,
                recurringCount: 3,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Not quite'), findsOneWidget);
    expect(
      find.text('Confuses active transport with diffusion'),
      findsOneWidget,
    );
    expect(find.text('Mastery 50% → 35%'), findsOneWidget);
    expect(find.textContaining('3 times in the last 14 days'), findsOneWidget);
  });
}
