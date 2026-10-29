import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/session_controller.dart';
import '../data/diagnostic_repository.dart';
import '../domain/diagnostic_models.dart';

part 'diagnostic_controller.g.dart';

/// Where the diagnostic run is: the attempt, the current question and the
/// answer picked for it.
class DiagnosticRun {
  const DiagnosticRun({
    this.attempt,
    this.index = 0,
    this.picked,
    this.busy = false,
    this.error,
    this.errorCode,
    this.result,
  });

  final DiagnosticAttempt? attempt;

  /// 0-based index of the question on screen.
  final int index;

  /// Option chosen on this question (saved when the student taps Next).
  final String? picked;

  /// Starting / saving / submitting / skipping.
  final bool busy;
  final String? error;
  final String? errorCode;

  /// Set after submit.
  final DiagnosticResult? result;

  DiagnosticQuestion? get question {
    final questions = attempt?.questions ?? const [];
    return index < questions.length ? questions[index] : null;
  }

  int get total => attempt?.total ?? 0;
  bool get isLast => attempt != null && index >= attempt!.questions.length - 1;
  bool get notEnoughQuestions => errorCode == 'NOT_ENOUGH_QUESTIONS';

  DiagnosticRun copyWith({
    DiagnosticAttempt? attempt,
    int? index,
    String? picked,
    bool clearPicked = false,
    bool? busy,
    String? error,
    String? errorCode,
    bool clearError = false,
    DiagnosticResult? result,
  }) => DiagnosticRun(
    attempt: attempt ?? this.attempt,
    index: index ?? this.index,
    picked: clearPicked ? null : (picked ?? this.picked),
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    result: result ?? this.result,
  );
}

/// The diagnostic flow, shared by intro -> questions -> result.
///
/// - Start: `POST /diagnostic/start` (same attempt after a restart; we
///   resume at the first unanswered question).
/// - Next: saves the answer with `POST /diagnostic/{id}/answer` BEFORE
///   moving on; the last one submits (`POST /diagnostic/{id}/submit`).
/// - Skip: `POST /diagnostic/skip`.
/// No right/wrong feedback is shown during the diagnostic.
@Riverpod(keepAlive: true)
class DiagnosticController extends _$DiagnosticController {
  @override
  DiagnosticRun build() => const DiagnosticRun();

  /// Starts or resumes. Returns true when there are questions to answer.
  Future<bool> start() async {
    if (state.busy) return false;
    final repo = ref.read(diagnosticRepositoryProvider);
    state = state.copyWith(busy: true, clearError: true);
    try {
      final attempt = await repo.start();
      // Resume at the first question without a saved answer.
      final firstOpen = attempt.questions.indexWhere(
        (q) => q.selectedOptionId == null,
      );
      final index = firstOpen < 0
          ? (attempt.questions.isEmpty ? 0 : attempt.questions.length - 1)
          : firstOpen;
      state = DiagnosticRun(
        attempt: attempt,
        index: index,
        picked: attempt.questions.elementAtOrNull(index)?.selectedOptionId,
      );
      return attempt.questions.isNotEmpty;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: ErrorMessages.of(e),
        errorCode: e is ApiException ? e.code : null,
      );
      return false;
    }
  }

  void pick(String optionId) {
    if (state.busy) return;
    state = state.copyWith(picked: optionId, clearError: true);
  }

  /// Saves the picked answer and moves on. On the last question it submits
  /// and returns the result (null otherwise or on error).
  Future<DiagnosticResult?> next() async {
    final run = state;
    final attempt = run.attempt;
    final question = run.question;
    final picked = run.picked;
    if (run.busy || attempt == null || question == null || picked == null) {
      return null;
    }
    final repo = ref.read(diagnosticRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    state = run.copyWith(busy: true, clearError: true);
    try {
      await repo.answer(
        attemptId: attempt.attemptId,
        questionId: question.id,
        optionId: picked,
      );
      // Remember the answer locally too (for going back after a restart).
      final questions = [...attempt.questions];
      questions[run.index] = question.copyWith(selectedOptionId: picked);
      final updated = attempt.copyWith(questions: questions);

      if (!run.isLast) {
        final nextIndex = run.index + 1;
        state = DiagnosticRun(
          attempt: updated,
          index: nextIndex,
          picked: questions[nextIndex].selectedOptionId,
        );
        return null;
      }

      final result = await repo.submit(attempt.attemptId);
      state = DiagnosticRun(attempt: updated, index: run.index, result: result);
      await session.refresh(); // diagnostic_completed = true
      return result;
    } catch (e) {
      state = run.copyWith(busy: false, error: ErrorMessages.of(e));
      return null;
    }
  }

  /// "Skip for now" (and the "still adding questions" empty state).
  Future<bool> skip() async {
    if (state.busy) return false;
    final repo = ref.read(diagnosticRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    state = state.copyWith(busy: true, clearError: true);
    try {
      await repo.skip();
      state = const DiagnosticRun();
      await session.refresh(); // diagnostic_skipped = true
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: ErrorMessages.of(e));
      return false;
    }
  }
}

/// The result for "Your starting point": from the submit we just did, or
/// `GET /diagnostic/result` (e.g. after a restart).
@riverpod
Future<DiagnosticResult> diagnosticResult(Ref ref) async {
  final fresh = ref.watch(diagnosticControllerProvider).result;
  if (fresh != null) return fresh;
  return ref.watch(diagnosticRepositoryProvider).result();
}
