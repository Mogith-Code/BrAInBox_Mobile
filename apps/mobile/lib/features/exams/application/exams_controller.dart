import 'package:brainbox_core/brainbox_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/exams_repository.dart';
import '../domain/exams_models.dart';

part 'exams_controller.freezed.dart';
part 'exams_controller.g.dart';

/// State of an in-progress exam attempt or generated paper session.
@freezed
abstract class ExamSessionState with _$ExamSessionState {
  const factory ExamSessionState({
    ExamPaper? paper,
    @Default({}) Map<String, String> answers,
    @Default(0) int elapsedSeconds,
    @Default(true) bool explain,
    @Default(false) bool isGenerating,
    @Default(false) bool isSubmitting,
    EvalResult? result,
    String? errorMessage,
  }) = _ExamSessionState;
}

/// Controller managing the active practice exam session.
@Riverpod(keepAlive: true)
class ExamSessionController extends _$ExamSessionController {
  @override
  ExamSessionState build() => const ExamSessionState();

  /// Sets or clears the chosen answer option ("A".."E") for a question.
  void selectAnswer(String questionId, String optionLetter) {
    final updated = Map<String, String>.from(state.answers);
    if (updated[questionId] == optionLetter) {
      // Toggle off if already selected
      updated.remove(questionId);
    } else {
      updated[questionId] = optionLetter;
    }
    state = state.copyWith(answers: updated);
  }

  /// Toggles whether AI explanations should be returned on submission.
  void toggleExplain(bool value) {
    state = state.copyWith(explain: value);
  }

  /// Increments the elapsed exam duration by 1 second.
  void tick() {
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
  }

  /// Initializes a new session directly with a provided paper.
  void setPaper(ExamPaper paper) {
    state = ExamSessionState(paper: paper);
  }

  /// Generates a new exam paper by unit selection and starts the session.
  Future<ExamPaper> generatePaper({
    required List<int> units,
    required int count,
  }) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);
    try {
      final repo = ref.read(examsRepositoryProvider);
      final paper = await repo.generatePaperByUnits(units: units, count: count);
      if (ref.mounted) {
        state = ExamSessionState(paper: paper);
      }
      return paper;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: ErrorMessages.of(e),
        );
      }
      rethrow;
    }
  }

  /// Submits the current answers to the backend for marking and explanation.
  Future<EvalResult> submit() async {
    final paper = state.paper;
    if (paper == null) throw StateError('No active paper to submit');

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final repo = ref.read(examsRepositoryProvider);
      final answers = [
        for (final q in paper.questions)
          AnswerItem(questionId: q.id, selected: state.answers[q.id]),
      ];
      final result = await repo.submitPaper(
        paperId: paper.paperId,
        answers: answers,
        explain: state.explain,
      );
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false, result: result);
      }
      return result;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: ErrorMessages.of(e),
        );
      }
      rethrow;
    }
  }

  /// Resets the session back to empty state.
  void reset() {
    state = const ExamSessionState();
  }
}

/// Overview / summary state for past papers and model papers.
@riverpod
class ExamsController extends _$ExamsController {
  @override
  Future<ExamsSummary> build() {
    return ref.watch(examsRepositoryProvider).fetchSummary();
  }

  /// Reloads the overview data.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(examsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }
}
