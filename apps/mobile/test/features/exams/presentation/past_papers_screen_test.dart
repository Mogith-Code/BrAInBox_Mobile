import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/exams/data/exams_repository.dart';
import 'package:brainbox_mobile/features/exams/domain/exams_models.dart';
import 'package:brainbox_mobile/features/exams/domain/paper_models.dart';
import 'package:brainbox_mobile/features/exams/presentation/exam_attempt_screen.dart';
import 'package:brainbox_mobile/features/exams/presentation/generate_paper_screen.dart';
import 'package:brainbox_mobile/features/exams/presentation/past_papers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ExamsRepository {}

const _summary = {
  'id': 'p1',
  'title': '2023 A/L Biology',
  'paper_type': 'past_paper',
  'year': 2023,
  'question_types': ['mcq', 'structured'],
  'question_count': 3,
  'outdated_count': 1,
  'total_marks': 10,
  'duration_minutes': 120,
};

Map<String, dynamic> _detail() => {
  'id': 'p1',
  'title': '2023 A/L Biology',
  'paper_type': 'past_paper',
  'year': 2023,
  'duration_minutes': 120,
  'total_marks': 10,
  'question_count': 2,
  'hidden_outdated': 0,
  'questions': [
    {
      'id': 'q1',
      'position': 1,
      'question_type': 'mcq',
      'topic': 'Genetics',
      'stem': 'What is a gene?',
      'marks': 1,
      'options': [
        {'label': 'A', 'text': 'A unit of heredity'},
        {'label': 'B', 'text': 'A protein'},
      ],
      'is_outdated': false,
    },
    {
      'id': 'q2',
      'position': 2,
      'question_type': 'structured',
      'topic': 'Cells',
      'stem': 'Describe mitosis.',
      'marks': 9,
      'is_outdated': true,
    },
  ],
};

Future<void> _pump(WidgetTester tester, ExamsRepository repo, String at) async {
  tester.view.physicalSize = const Size(420, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(
        path: AppRoutes.pastPapers,
        builder: (_, _) => const PastPapersScreen(),
      ),
      GoRoute(
        path: AppRoutes.generatePaper,
        builder: (_, _) => const GeneratePaperScreen(initialUnits: [6]),
      ),
      GoRoute(
        path: AppRoutes.examAttempt,
        builder: (_, s) => ExamAttemptScreen(
          paperId: s.pathParameters['paperId']!,
          hideOutdated: s.uri.queryParameters['hide_outdated'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.examResult,
        builder: (_, _) => const Scaffold(body: Text('RESULT')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [examsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(const PaperBlueprint(unitNumbers: [1])));

  late _MockRepo repo;
  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.listPapers(
        year: any(named: 'year'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => [PaperSummary.fromJson(_summary)]);
    when(
      () => repo.fetchPaper(any(), hideOutdated: any(named: 'hideOutdated')),
    ).thenAnswer((_) async => PaperDetail.fromJson(_detail()));
  });

  testWidgets('lists past papers and opens one with hide outdated', (
    tester,
  ) async {
    await _pump(tester, repo, AppRoutes.pastPapers);
    expect(find.text('2023 A/L Biology'), findsOneWidget);
    expect(find.text('1 outdated'), findsOneWidget);

    await tester.tap(find.text('Hide outdated questions'));
    await tester.pumpAndSettle();
    expect(find.text('1 outdated hidden'), findsOneWidget);

    await tester.tap(find.text('2023 A/L Biology'));
    await tester.pumpAndSettle();
    verify(() => repo.fetchPaper('p1', hideOutdated: true)).called(1);
  });

  testWidgets('shows the empty state', (tester) async {
    when(
      () => repo.listPapers(
        year: any(named: 'year'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => []);
    await _pump(tester, repo, AppRoutes.pastPapers);
    expect(find.text('No past papers'), findsOneWidget);
  });

  testWidgets('shows the error state with retry', (tester) async {
    when(
      () => repo.listPapers(
        year: any(named: 'year'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) async => throw const ApiException(code: 'x', message: 'Server down'),
    );
    await _pump(tester, repo, AppRoutes.pastPapers);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets('exam mode: tabs, palette, flag and submit confirmation', (
    tester,
  ) async {
    when(
      () => repo.submitPaper(
        paperId: any(named: 'paperId'),
        answers: any(named: 'answers'),
      ),
    ).thenAnswer(
      (_) async => const EvalResult(paperId: 'p1', pendingWritten: 1),
    );
    await _pump(tester, repo, AppRoutes.examAttemptPath('p1'));

    expect(find.text('Part I · MCQ'), findsOneWidget);
    expect(find.text('Part II · Structured'), findsOneWidget);
    expect(find.text('Unanswered'), findsOneWidget);

    await tester.tap(find.text('A unit of heredity'));
    await tester.pumpAndSettle();
    expect(find.text('Answered'), findsOneWidget);

    await tester.tap(find.byTooltip('Flag for review'));
    await tester.pumpAndSettle();
    expect(find.text('Flagged'), findsOneWidget);

    await tester.tap(find.byTooltip('Question palette'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Question 1, Flagged'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 2, Unanswered'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Question 2, Unanswered'));
    await tester.pumpAndSettle();
    expect(find.text('Describe mitosis.'), findsOneWidget);
    expect(find.text('Outdated syllabus'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Prophase first');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit paper'));
    await tester.pumpAndSettle();
    expect(find.text('Submit paper?'), findsOneWidget);
    expect(find.text('Answered: 2'), findsOneWidget);
    expect(find.text('Flagged: 1'), findsOneWidget);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    final answers =
        verify(
              () => repo.submitPaper(
                paperId: 'p1',
                answers: captureAny(named: 'answers'),
              ),
            ).captured.single
            as List<AnswerItem>;
    expect(answers[0].selected, 'A');
    expect(answers[1].answerText, 'Prophase first');
    expect(find.text('RESULT'), findsOneWidget);
  });

  testWidgets('generate: starts the job, polls, then opens the paper', (
    tester,
  ) async {
    when(
      () => repo.startModelPaper(any()),
    ).thenAnswer((_) async => const PaperJob(jobId: 'j1', toGenerate: 20));
    when(() => repo.watchJob('j1')).thenAnswer(
      (_) => Stream.fromIterable(const [
        AiJob(id: 'j1', status: AiJobStatus.running, progress: 0.5),
        AiJob(
          id: 'j1',
          status: AiJobStatus.succeeded,
          result: {'paper_id': 'p1'},
        ),
      ]),
    );
    await _pump(tester, repo, AppRoutes.generatePaper);

    await tester.tap(find.byTooltip('More Essay'));
    await tester.tap(find.text('Generate paper'));
    await tester.pumpAndSettle();

    final bp =
        verify(() => repo.startModelPaper(captureAny())).captured.single
            as PaperBlueprint;
    expect(bp.unitNumbers, [6]);
    expect(bp.mcqCount, 20);
    expect(bp.essayCount, 1);
    expect(find.text('What is a gene?'), findsOneWidget);
  });

  testWidgets('generate: a failed job shows the error', (tester) async {
    when(
      () => repo.startModelPaper(any()),
    ).thenAnswer((_) async => const PaperJob(jobId: 'j2'));
    when(() => repo.watchJob('j2')).thenAnswer(
      (_) => Stream.value(
        const AiJob(
          id: 'j2',
          status: AiJobStatus.failed,
          error: 'Daily limit reached',
        ),
      ),
    );
    await _pump(tester, repo, AppRoutes.generatePaper);
    await tester.tap(find.text('Generate paper'));
    await tester.pumpAndSettle();
    expect(find.text('Daily limit reached'), findsOneWidget);
  });
}
