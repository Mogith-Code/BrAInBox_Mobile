import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/practice/application/diagnostic_controller.dart';
import 'package:brainbox_mobile/features/practice/data/diagnostic_repository.dart';
import 'package:brainbox_mobile/features/practice/data/fake_diagnostic_repository.dart';
import 'package:brainbox_mobile/features/practice/domain/diagnostic_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements DiagnosticRepository {}

class _FakeSession extends Session {
  int refreshed = 0;

  @override
  Future<SessionState> build() async => const SessionState(welcomeSeen: true);

  @override
  Future<void> refresh() async => refreshed++;
}

DiagnosticQuestion _q(int i, {String? selected}) => DiagnosticQuestion(
  id: 'q$i',
  unitCode: 'U$i',
  unitTitle: 'Unit $i',
  stem: 'Question $i?',
  options: [
    DiagnosticOption(id: 'q$i-a', label: 'A', text: 'a'),
    DiagnosticOption(id: 'q$i-b', label: 'B', text: 'b'),
  ],
  selectedOptionId: selected,
);

void main() {
  late _MockRepo repo;
  late _FakeSession session;
  late ProviderContainer c;

  setUp(() {
    repo = _MockRepo();
    session = _FakeSession();
    c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        diagnosticRepositoryProvider.overrideWithValue(repo),
        sessionProvider.overrideWith(() => session),
      ],
    );
    addTearDown(c.dispose);
  });

  DiagnosticController ctrl() => c.read(diagnosticControllerProvider.notifier);
  DiagnosticRun run() => c.read(diagnosticControllerProvider);

  test('resumes at the first unanswered question', () async {
    when(() => repo.start()).thenAnswer(
      (_) async => DiagnosticAttempt(
        attemptId: 'a1',
        total: 3,
        questions: [
          _q(1, selected: 'q1-a'),
          _q(2),
          _q(3),
        ],
      ),
    );
    expect(await ctrl().start(), isTrue);
    expect(run().index, 1);
    expect(run().picked, isNull);
  });

  test('saves each answer before moving on, then submits', () async {
    when(() => repo.start()).thenAnswer(
      (_) async => DiagnosticAttempt(
        attemptId: 'a1',
        total: 2,
        questions: [_q(1), _q(2)],
      ),
    );
    when(
      () => repo.answer(
        attemptId: any(named: 'attemptId'),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
      ),
    ).thenAnswer((_) async => const AnswerSaved(answered: 1, total: 2));
    when(
      () => repo.submit('a1'),
    ).thenAnswer((_) async => FakeDiagnosticRepository.figmaResult('a1'));

    await ctrl().start();
    expect(await ctrl().next(), isNull); // nothing picked yet
    ctrl().pick('q1-b');
    expect(await ctrl().next(), isNull); // not the last one
    verify(
      () => repo.answer(attemptId: 'a1', questionId: 'q1', optionId: 'q1-b'),
    ).called(1);
    expect(run().index, 1);

    ctrl().pick('q2-a');
    final result = await ctrl().next();
    expect(result, isNotNull);
    expect(result!.needsWork!.unitTitle, 'Genetics');
    verify(() => repo.submit('a1')).called(1);
    expect(session.refreshed, 1);
  });

  test('a failed save keeps the question and shows the error', () async {
    when(() => repo.start()).thenAnswer(
      (_) async => DiagnosticAttempt(
        attemptId: 'a1',
        total: 2,
        questions: [_q(1), _q(2)],
      ),
    );
    when(
      () => repo.answer(
        attemptId: any(named: 'attemptId'),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
      ),
    ).thenThrow(const ApiException(code: 'network', message: 'offline'));
    await ctrl().start();
    ctrl().pick('q1-a');
    await ctrl().next();
    expect(run().index, 0);
    expect(run().picked, 'q1-a');
    expect(run().error, 'No internet connection. Check it and try again.');
  });

  test('NOT_ENOUGH_QUESTIONS is reported', () async {
    when(
      () => repo.start(),
    ).thenThrow(const ApiException(code: 'NOT_ENOUGH_QUESTIONS', message: 'm'));
    expect(await ctrl().start(), isFalse);
    expect(run().notEnoughQuestions, isTrue);
  });

  test('skip calls the API and refreshes the session', () async {
    when(() => repo.skip()).thenAnswer((_) async {});
    expect(await ctrl().skip(), isTrue);
    verify(() => repo.skip()).called(1);
    expect(session.refreshed, 1);
  });

  test('result comes from GET /diagnostic/result after a restart', () async {
    when(
      () => repo.result(),
    ).thenAnswer((_) async => FakeDiagnosticRepository.figmaResult('a1'));
    final sub = c.listen(diagnosticResultProvider, (_, _) {});
    addTearDown(sub.close);
    final result = await c.read(diagnosticResultProvider.future);
    expect(result.units, hasLength(10));
    expect(result.units[3].fraction, closeTo(0.88, 0.001));
  });
}
