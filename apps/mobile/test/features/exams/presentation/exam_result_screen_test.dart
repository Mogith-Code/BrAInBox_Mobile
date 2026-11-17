import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/exams/domain/exams_models.dart';
import 'package:brainbox_mobile/features/exams/presentation/exam_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('See my next steps opens the recommendations', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const result = EvalResult(
      paperId: 'p1',
      totalQuestions: 1,
      answered: 1,
      correct: 1,
      percent: 100,
      byTopic: [TopicScore(topic: 'Genetics', correct: 1, total: 1)],
      results: [
        QuestionResult(
          questionId: 'q1',
          topic: 'Genetics',
          question: 'What is a gene?',
          selectedOption: 'A',
          correctAnswer: 'A',
          isCorrect: true,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/result',
      routes: [
        GoRoute(
          path: '/result',
          builder: (_, _) => const ExamResultScreen(
            paper: ExamPaper(paperId: 'p1'),
            result: result,
          ),
        ),
        GoRoute(
          path: AppRoutes.nextSteps,
          builder: (_, s) => Scaffold(body: Text('AT ${s.uri}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('See my next steps'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('See my next steps'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.nextSteps}'), findsOneWidget);
  });
}
