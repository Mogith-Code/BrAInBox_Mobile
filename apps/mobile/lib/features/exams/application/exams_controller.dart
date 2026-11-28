import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exams_repository.dart';
import '../domain/exams_models.dart';
import '../domain/paper_models.dart';

// ------------------------------------------------------------ past papers

/// Filters of the past papers list.
typedef PapersQuery = ({int? year, PaperQuestionType? type});

/// `GET /papers` for one set of filters.
final pastPapersProvider = FutureProvider.autoDispose
    .family<List<PaperSummary>, PapersQuery>(
      (ref, q) => ref
          .watch(examsRepositoryProvider)
          .listPapers(year: q.year, type: q.type),
    );

// ------------------------------------------------------------ generate

/// State of `POST /papers/generate` + job polling.
class GenerateState {
  const GenerateState({
    this.running = false,
    this.progress,
    this.paperId,
    this.warnings = const [],
    this.error,
  });

  final bool running;
  final double? progress;
  final String? paperId;
  final List<String> warnings;
  final String? error;
}

class GeneratePaperController extends Notifier<GenerateState> {
  StreamSubscription<AiJob>? _sub;

  @override
  GenerateState build() {
    ref.onDispose(() => _sub?.cancel());
    return const GenerateState();
  }

  /// Starts the job and polls it. Resolves to the new paper id, or null.
  Future<String?> generate(PaperBlueprint blueprint) async {
    state = const GenerateState(running: true);
    final repo = ref.read(examsRepositoryProvider);
    try {
      final job = await repo.startModelPaper(blueprint);
      final done = Completer<String?>();
      await _sub?.cancel();
      _sub = repo
          .watchJob(job.jobId)
          .listen(
            (j) {
              if (!ref.mounted) return;
              if (j.status == AiJobStatus.succeeded) {
                final id = j.result?['paper_id'] as String?;
                state = GenerateState(
                  paperId: id,
                  warnings: [
                    for (final w in (j.result?['warnings'] as List? ?? []))
                      '$w',
                  ],
                  error: id == null ? 'The paper could not be created.' : null,
                );
                if (!done.isCompleted) done.complete(id);
              } else if (j.isDone) {
                state = GenerateState(
                  error: j.error ?? 'The paper could not be created.',
                );
                if (!done.isCompleted) done.complete(null);
              } else {
                state = GenerateState(running: true, progress: j.progress);
              }
            },
            onError: (Object e) {
              if (ref.mounted) {
                state = GenerateState(error: ErrorMessages.of(e));
              }
              if (!done.isCompleted) done.complete(null);
            },
          );
      return await done.future;
    } catch (e) {
      if (ref.mounted) state = GenerateState(error: ErrorMessages.of(e));
      return null;
    }
  }
}

final generatePaperControllerProvider =
    NotifierProvider.autoDispose<GeneratePaperController, GenerateState>(
      GeneratePaperController.new,
    );

// ------------------------------------------------------------ exam mode

/// Answers, flags and submit status of one exam attempt.
class ExamAttemptState {
  const ExamAttemptState({
    this.mcq = const {},
    this.written = const {},
    this.flagged = const {},
    this.submitting = false,
    this.error,
  });

  /// question id -> "A".."E"
  final Map<String, String> mcq;

  /// question id -> answer text (structured / essay)
  final Map<String, String> written;
  final Set<String> flagged;
  final bool submitting;
  final String? error;

  bool isAnswered(String questionId) =>
      mcq.containsKey(questionId) ||
      (written[questionId]?.trim().isNotEmpty ?? false);

  /// True once leaving the exam would lose an answer or a flag.
  bool get hasProgress =>
      mcq.isNotEmpty ||
      flagged.isNotEmpty ||
      written.values.any((text) => text.trim().isNotEmpty);

  ExamAttemptState copyWith({
    Map<String, String>? mcq,
    Map<String, String>? written,
    Set<String>? flagged,
    bool? submitting,
    String? error,
  }) => ExamAttemptState(
    mcq: mcq ?? this.mcq,
    written: written ?? this.written,
    flagged: flagged ?? this.flagged,
    submitting: submitting ?? this.submitting,
    error: error,
  );
}

class ExamAttemptController extends Notifier<ExamAttemptState> {
  ExamAttemptController(this.paperId);

  final String paperId;

  @override
  ExamAttemptState build() => const ExamAttemptState();

  void selectOption(String questionId, String letter) {
    final next = Map<String, String>.from(state.mcq);
    if (next[questionId] == letter) {
      next.remove(questionId);
    } else {
      next[questionId] = letter;
    }
    state = state.copyWith(mcq: next);
  }

  void setWritten(String questionId, String text) {
    state = state.copyWith(written: {...state.written, questionId: text});
  }

  void toggleFlag(String questionId) {
    final next = Set<String>.from(state.flagged);
    if (!next.remove(questionId)) next.add(questionId);
    state = state.copyWith(flagged: next);
  }

  /// Submits every question of [paper]. Stores the result in
  /// [examSessionControllerProvider] for the result screen.
  Future<EvalResult?> submit(PaperDetail paper) async {
    state = state.copyWith(submitting: true);
    try {
      final answers = [
        for (final q in paper.questions)
          q.type == PaperQuestionType.mcq
              ? AnswerItem(questionId: q.id, selected: state.mcq[q.id])
              : AnswerItem(
                  questionId: q.id,
                  answerText: (state.written[q.id]?.trim().isEmpty ?? true)
                      ? null
                      : state.written[q.id]!.trim(),
                ),
      ];
      final result = await ref
          .read(examsRepositoryProvider)
          .submitPaper(paperId: paperId, answers: answers);
      ref
          .read(examSessionControllerProvider.notifier)
          .setResult(toExamPaper(paper), result);
      if (ref.mounted) state = state.copyWith(submitting: false);
      return result;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(submitting: false, error: ErrorMessages.of(e));
      }
      return null;
    }
  }
}

final examAttemptControllerProvider = NotifierProvider.autoDispose
    .family<ExamAttemptController, ExamAttemptState, String>(
      ExamAttemptController.new,
    );

/// `GET /papers/{id}`; the bool is `hide_outdated`.
final paperDetailProvider = FutureProvider.autoDispose
    .family<PaperDetail, ({String id, bool hideOutdated})>(
      (ref, a) => ref
          .watch(examsRepositoryProvider)
          .fetchPaper(a.id, hideOutdated: a.hideOutdated),
    );

/// The result screen's paper model (MCQs only carry options).
ExamPaper toExamPaper(PaperDetail p) => ExamPaper(
  paperId: p.id,
  title: p.title,
  totalQuestions: p.questions.length,
  questions: [
    for (final q in p.questions)
      ExamQuestion(
        id: q.id,
        topicId: q.topicId,
        topic: q.topic,
        question: q.stem,
        options: [for (final o in q.options) o.text],
        marks: q.marks,
      ),
  ],
);

// ------------------------------------------------------------ last result

/// The last submitted paper and its result (read by the result screen).
class ExamSessionState {
  const ExamSessionState({this.paper, this.result});

  final ExamPaper? paper;
  final EvalResult? result;
}

class ExamSessionController extends Notifier<ExamSessionState> {
  @override
  ExamSessionState build() => const ExamSessionState();

  void setResult(ExamPaper paper, EvalResult result) {
    state = ExamSessionState(paper: paper, result: result);
  }

  void reset() => state = const ExamSessionState();
}

final examSessionControllerProvider =
    NotifierProvider<ExamSessionController, ExamSessionState>(
      ExamSessionController.new,
    );
