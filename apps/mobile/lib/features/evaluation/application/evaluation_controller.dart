import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/evaluation_repository.dart';
import '../domain/evaluation_models.dart';

/// Filters of the written-practice list.
typedef WrittenFilter = ({String? type, bool hideOutdated});

/// The structured / essay questions to practise.
final writtenQuestionsProvider = FutureProvider.autoDispose
    .family<List<WrittenQuestion>, WrittenFilter>(
      (ref, filter) => ref
          .watch(evaluationRepositoryProvider)
          .fetchQuestions(type: filter.type, hideOutdated: filter.hideOutdated),
    );

/// The text of one question (shown above the answer box).
final questionStemProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, questionId) =>
      ref.watch(evaluationRepositoryProvider).fetchQuestionStem(questionId),
);

/// One checked answer.
final evaluationProvider = FutureProvider.autoDispose
    .family<Evaluation, String>(
      (ref, evaluationId) =>
          ref.watch(evaluationRepositoryProvider).fetchEvaluation(evaluationId),
    );

/// What the "check my answer" buttons are doing.
class SubmitState {
  const SubmitState({this.isBusy = false, this.message, this.errorMessage});

  final bool isBusy;

  /// Shown under the AI loader, e.g. "Reading your handwriting...".
  final String? message;
  final String? errorMessage;
}

/// Sends answers for OCR and marking and waits for the result.
class EvaluationSubmitController extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState();

  EvaluationRepository get _repository =>
      ref.read(evaluationRepositoryProvider);

  /// Marks a typed answer. Returns the evaluation id, or null on failure.
  Future<String?> evaluate({
    required String questionId,
    required String answerText,
    String? evaluationId,
  }) => _run(
    'Checking your answer against the marking points...',
    () => _repository.evaluate(
      questionId: questionId,
      answerText: answerText,
      evaluationId: evaluationId,
    ),
  );

  /// Uploads photos and reads them. Returns the evaluation id whose text
  /// the student checks next, or null on failure.
  Future<String?> readHandwriting({
    required String questionId,
    required List<AnswerPage> pages,
  }) => _run(
    'Reading your handwriting...',
    () => _repository.readHandwriting(questionId: questionId, pages: pages),
  );

  Future<String?> _run(String message, Future<String> Function() work) async {
    if (state.isBusy) return null;
    state = SubmitState(isBusy: true, message: message);
    try {
      final id = await work();
      ref.invalidate(evaluationProvider(id));
      state = const SubmitState();
      return id;
    } catch (error) {
      state = SubmitState(errorMessage: ErrorMessages.of(error));
      return null;
    }
  }

  void clearError() => state = const SubmitState();
}

final evaluationSubmitProvider =
    NotifierProvider.autoDispose<EvaluationSubmitController, SubmitState>(
      EvaluationSubmitController.new,
    );
