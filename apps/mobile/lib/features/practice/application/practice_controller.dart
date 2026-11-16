import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/practice_repository.dart';
import '../domain/practice_models.dart';

/// The Practice tab overview. Reload with `ref.invalidate(practiceHubProvider)`.
final practiceHubProvider = FutureProvider.autoDispose<PracticeHub>(
  (ref) => ref.watch(practiceRepositoryProvider).fetchHub(),
);

/// The units shown in the quiz setup.
final practiceUnitsProvider = FutureProvider<List<PracticeUnit>>(
  (ref) => ref.watch(practiceRepositoryProvider).fetchUnits(),
);

/// A finished quiz's result.
final quizResultProvider = FutureProvider.autoDispose
    .family<QuizResult, String>(
      (ref, quizId) =>
          ref.watch(practiceRepositoryProvider).fetchResult(quizId),
    );

/// State of the quiz the student is taking.
class QuizSessionState {
  const QuizSessionState({
    this.quiz,
    this.index = 0,
    this.feedback = const {},
    this.isLoading = false,
    this.isAnswering = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final Quiz? quiz;

  /// Index of the question on screen.
  final int index;

  /// Feedback per question id, for the questions answered in this session.
  final Map<String, AnswerFeedback> feedback;
  final bool isLoading;
  final bool isAnswering;
  final bool isSubmitting;
  final String? errorMessage;

  QuizQuestion? get current {
    final questions = quiz?.questions ?? const <QuizQuestion>[];
    return index < questions.length ? questions[index] : null;
  }

  AnswerFeedback? get currentFeedback => feedback[current?.id];
  bool get isLast => quiz != null && index >= quiz!.questions.length - 1;

  QuizSessionState copyWith({
    Quiz? quiz,
    int? index,
    Map<String, AnswerFeedback>? feedback,
    bool? isLoading,
    bool? isAnswering,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) => QuizSessionState(
    quiz: quiz ?? this.quiz,
    index: index ?? this.index,
    feedback: feedback ?? this.feedback,
    isLoading: isLoading ?? this.isLoading,
    isAnswering: isAnswering ?? this.isAnswering,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

/// Runs one quiz: start or resume, answer, flag, move, submit.
class QuizSessionController extends Notifier<QuizSessionState> {
  DateTime _shownAt = DateTime.now();

  @override
  QuizSessionState build() => const QuizSessionState();

  PracticeRepository get _repository => ref.read(practiceRepositoryProvider);

  /// Starts a new quiz. Returns its id, or null when it could not start
  /// (the reason is in `state.errorMessage`).
  Future<String?> start(QuizSetup setup) async {
    state = const QuizSessionState(isLoading: true);
    try {
      final quiz = await _repository.startQuiz(setup);
      _open(quiz);
      return quiz.quizId;
    } catch (error) {
      state = QuizSessionState(errorMessage: ErrorMessages.of(error));
      return null;
    }
  }

  /// Loads a quiz by id (resume, or opening the screen after a restart).
  Future<void> load(String quizId) async {
    if (state.quiz?.quizId == quizId) return;
    state = const QuizSessionState(isLoading: true);
    try {
      _open(await _repository.fetchQuiz(quizId));
    } catch (error) {
      state = QuizSessionState(errorMessage: ErrorMessages.of(error));
    }
  }

  void _open(Quiz quiz) {
    // Resume at the first question that is not answered yet.
    final next = quiz.questions.indexWhere((q) => !q.isAnswered);
    state = QuizSessionState(quiz: quiz, index: next < 0 ? 0 : next);
    _shownAt = DateTime.now();
  }

  /// Answers the question on screen. The answer is final: the feedback
  /// shows the solution.
  Future<void> answer(String optionId) async {
    final quiz = state.quiz;
    final question = state.current;
    if (quiz == null || question == null || question.isAnswered) return;
    if (state.isAnswering) return;
    state = state.copyWith(isAnswering: true, clearError: true);
    try {
      final feedback = await _repository.answer(
        quizId: quiz.quizId,
        questionId: question.id,
        optionId: optionId,
        timeSpentSeconds: DateTime.now().difference(_shownAt).inSeconds,
      );
      state = state.copyWith(
        quiz: quiz.copyWithQuestion(
          question.copyWith(
            selectedOptionId: feedback.selectedOptionId,
            correctOptionId: feedback.correctOptionId,
            isCorrect: feedback.isCorrect,
          ),
        ),
        feedback: {...state.feedback, question.id: feedback},
        isAnswering: false,
      );
    } catch (error) {
      state = state.copyWith(
        isAnswering: false,
        errorMessage: ErrorMessages.of(error),
      );
    }
  }

  /// Flags / unflags the question on screen for review.
  Future<void> toggleFlag() async {
    final quiz = state.quiz;
    final question = state.current;
    if (quiz == null || question == null) return;
    final flagged = !question.flagged;
    state = state.copyWith(
      quiz: quiz.copyWithQuestion(question.copyWith(flagged: flagged)),
    );
    try {
      await _repository.flag(
        quizId: quiz.quizId,
        questionId: question.id,
        flagged: flagged,
      );
    } catch (_) {
      // The flag is only a reminder: keep it on screen even if saving failed.
    }
  }

  void goTo(int index) {
    final count = state.quiz?.questions.length ?? 0;
    if (index < 0 || index >= count) return;
    state = state.copyWith(index: index, clearError: true);
    _shownAt = DateTime.now();
  }

  void next() => goTo(state.index + 1);

  /// Finishes the quiz. Returns true when the result is ready.
  Future<bool> submit() async {
    final quiz = state.quiz;
    if (quiz == null || state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.submit(quiz.quizId);
      ref.invalidate(quizResultProvider(quiz.quizId));
      ref.invalidate(practiceHubProvider);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ErrorMessages.of(error),
      );
      return false;
    }
  }

  Future<String?> report(String questionId, String reason) async {
    try {
      await _repository.reportQuestion(questionId, reason);
      return null;
    } catch (error) {
      return ErrorMessages.of(error);
    }
  }
}

final quizSessionProvider =
    NotifierProvider<QuizSessionController, QuizSessionState>(
      QuizSessionController.new,
    );
