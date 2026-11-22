import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/admin_errors.dart';

import '../../question_bank/data/question_bank_repository.dart';
import '../data/mcq_mapping_repository.dart';
import '../domain/mcq_mapping_models.dart';

// The question for the editor is the question bank's
// `questionDetailProvider(id)` (GET /admin/questions/{id}).
export '../../question_bank/application/question_bank_controller.dart'
    show questionDetailProvider;

/// The page of the MCQ list on the left.
class McqPageController extends Notifier<int> {
  @override
  int build() => 1;

  void set(int page) => state = page;
}

final mcqPageProvider = NotifierProvider.autoDispose<McqPageController, int>(
  McqPageController.new,
);

/// MCQs to pick from (`GET /admin/questions?type=mcq&page=`).
final mcqListProvider = FutureProvider.autoDispose<QuestionPage>(
  (ref) => ref
      .watch(questionBankRepositoryProvider)
      .questions(
        QuestionFilter(
          type: QuestionKind.mcq,
          page: ref.watch(mcqPageProvider),
        ),
      ),
);

/// Saves the question with `PUT /admin/questions/{id}`, keeping its status
/// (an approved question must still pass the publish rules).
class McqSaveController extends Notifier<bool> {
  @override
  bool build() => false; // saving?

  Future<({QuestionDetail? saved, String? error})> save(
    QuestionDetail question,
  ) async {
    state = true;
    try {
      final saved = await ref
          .read(questionBankRepositoryProvider)
          .save(question);
      if (ref.mounted) ref.invalidate(mcqListProvider);
      return (saved: saved, error: null);
    } catch (e) {
      return (saved: null, error: adminErrorMessage(e));
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final mcqSaveProvider = NotifierProvider.autoDispose<McqSaveController, bool>(
  McqSaveController.new,
);

/// "Suggest with AI" for one question. The admin accepts or dismisses each
/// suggestion; only accepted ones are saved.
class SuggestionsController extends Notifier<SuggestionsState> {
  SuggestionsController(this.questionId);

  final String questionId;

  McqMappingRepository get _repository =>
      ref.read(mcqMappingRepositoryProvider);

  @override
  SuggestionsState build() => const SuggestionsState();

  Future<void> run() async {
    state = const SuggestionsState(running: true);
    try {
      final items = await _repository.suggest(questionId);
      if (ref.mounted) state = SuggestionsState(items: items);
    } catch (e) {
      if (ref.mounted) state = SuggestionsState(error: adminErrorMessage(e));
    }
  }

  /// Saves the suggestion for its option. Returns an error sentence or null.
  Future<String?> accept(MisconceptionSuggestion s) async {
    state = state.copyWith(saving: {...state.saving, s.optionId});
    try {
      await _repository.confirm(s.optionId, s.suggested);
      if (!ref.mounted) return null;
      state = state.copyWith(
        decisions: {
          ...state.decisions,
          s.optionId: SuggestionDecision.accepted,
        },
        saving: {...state.saving}..remove(s.optionId),
      );
      return null;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(saving: {...state.saving}..remove(s.optionId));
      }
      return adminErrorMessage(e);
    }
  }

  void dismiss(MisconceptionSuggestion s) => state = state.copyWith(
    decisions: {...state.decisions, s.optionId: SuggestionDecision.dismissed},
  );
}

final suggestionsProvider = NotifierProvider.autoDispose
    .family<SuggestionsController, SuggestionsState, String>(
      SuggestionsController.new,
    );
