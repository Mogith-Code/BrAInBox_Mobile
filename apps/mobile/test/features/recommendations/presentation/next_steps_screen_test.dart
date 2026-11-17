import 'package:brainbox_mobile/features/recommendations/data/recommendations_repository.dart';
import 'package:brainbox_mobile/features/recommendations/domain/recommendations_models.dart';
import 'package:brainbox_mobile/features/recommendations/presentation/next_steps_screen.dart';
import 'package:brainbox_mobile/features/recommendations/presentation/study_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements RecommendationsRepository {}

void main() {
  Widget app(RecommendationsRepository repository, Widget home) =>
      ProviderScope(
        overrides: [
          recommendationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: home),
      );

  testWidgets('each next step shows why it was recommended', (tester) async {
    final repository = _MockRepository();
    when(repository.fetchNextSteps).thenAnswer(
      (_) async => const NextSteps(
        items: [
          NextStep(
            id: 'r1',
            action: 'revise_note',
            title: 'Revise: Active transport',
            reason: 'Because you missed 3 questions on “Active transport”.',
            priority: 1,
            estimatedMinutes: 15,
            unitNumber: 2,
            topic: 'Cell membrane',
          ),
        ],
      ),
    );

    await tester.pumpWidget(app(repository, const NextStepsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Revise: Active transport'), findsOneWidget);
    expect(
      find.text('Because you missed 3 questions on “Active transport”.'),
      findsOneWidget,
    );
    expect(find.text('Unit 2 · Cell membrane · 15 min'), findsOneWidget);
    expect(find.text('Do first'), findsOneWidget);
    expect(find.text('Open short notes'), findsOneWidget);
  });

  testWidgets('a new student sees the hint instead of made-up steps', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(repository.fetchNextSteps).thenAnswer(
      (_) async =>
          const NextSteps(hint: 'Take the diagnostic or a quiz first.'),
    );

    await tester.pumpWidget(app(repository, const NextStepsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No next steps yet'), findsOneWidget);
    expect(find.text('Take the diagnostic or a quiz first.'), findsOneWidget);
  });

  testWidgets('ticking a plan item saves it and updates the progress', (
    tester,
  ) async {
    final repository = _MockRepository();
    final today = DateTime.now();
    when(repository.fetchPlan).thenAnswer(
      (_) async => StudyPlan(
        id: 'p1',
        title: 'Week of 16 Nov',
        total: 1,
        days: [
          PlanDay(
            date: today,
            weekday: 'mon',
            isStudyDay: true,
            minutesPlanned: 15,
            minutesAvailable: 60,
            items: const [
              PlanItem(
                id: 'i1',
                title: 'Revise: Active transport',
                isDone: false,
                action: 'revise_note',
                estimatedMinutes: 15,
              ),
            ],
          ),
        ],
      ),
    );
    when(
      () => repository.setItemDone('i1', done: true),
    ).thenAnswer((_) async {});
    when(repository.fetchNextSteps).thenAnswer((_) async => const NextSteps());

    await tester.pumpWidget(app(repository, const StudyPlanScreen()));
    await tester.pumpAndSettle();
    expect(find.text('0 of 1 done'), findsOneWidget);
    expect(find.text('15 of 60 min'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('1 of 1 done'), findsOneWidget);
    verify(() => repository.setItemDone('i1', done: true)).called(1);
  });
}
