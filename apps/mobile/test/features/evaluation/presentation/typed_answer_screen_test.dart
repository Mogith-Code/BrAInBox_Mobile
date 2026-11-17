import 'package:brainbox_mobile/features/evaluation/data/evaluation_repository.dart';
import 'package:brainbox_mobile/features/evaluation/domain/evaluation_models.dart';
import 'package:brainbox_mobile/features/evaluation/presentation/evaluation_feedback_screen.dart';
import 'package:brainbox_mobile/features/evaluation/presentation/typed_answer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EvaluationRepository {}

void main() {
  testWidgets('the check button is off until something is typed', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(
      () => repository.fetchQuestionStem('q1'),
    ).thenAnswer((_) async => 'Describe active transport.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [evaluationRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: TypedAnswerScreen(questionId: 'q1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Describe active transport.'), findsOneWidget);
    FilledButton button() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Check my answer'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ATP is needed');
    await tester.pump();
    expect(find.text('3 words'), findsOneWidget);
    expect(button().onPressed, isNotNull);
  });

  testWidgets('feedback shows marks, points and the disclaimer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 6000);
    addTearDown(tester.view.reset);
    final repository = _MockRepository();
    when(() => repository.fetchEvaluation('e1')).thenAnswer(
      (_) async => const Evaluation(
        id: 'e1',
        questionId: 'q1',
        question: 'Describe active transport.',
        status: 'succeeded',
        source: 'typed',
        answerText: 'It moves against the gradient.',
        estimatedMarks: 2,
        maxMarks: 4,
        percent: 50,
        covered: 1,
        missing: 1,
        points: [
          PointResult(
            text: 'Moves against the concentration gradient',
            marks: 2,
            status: 'covered',
            marksAwarded: 2,
          ),
          PointResult(
            text: 'ATP is required',
            marks: 2,
            status: 'missing',
            marksAwarded: 0,
          ),
        ],
        tips: ['Add this point: ATP is required'],
        modelAnswer: 'Model answer text',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [evaluationRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: EvaluationFeedbackScreen(evaluationId: 'e1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('1 covered · 0 partial · 1 missing'), findsOneWidget);
    expect(find.text('Missing · 0 of 2 marks'), findsOneWidget);
    expect(find.text('Add this point: ATP is required'), findsOneWidget);
    expect(
      find.text('Formative feedback – not an official exam mark.'),
      findsOneWidget,
    );
  });
}
