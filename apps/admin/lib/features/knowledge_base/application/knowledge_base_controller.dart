import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../data/knowledge_base_repository.dart';
import '../domain/knowledge_base_models.dart';

/// The "Status" filter (null = any).
class StatusFilterController extends Notifier<ReviewStatus?> {
  @override
  ReviewStatus? build() => null;

  void set(ReviewStatus? status) => state = status;
}

final modelAnswerStatusProvider =
    NotifierProvider.autoDispose<StatusFilterController, ReviewStatus?>(
      StatusFilterController.new,
    );

/// The model answers for the filter, plus adding one and editing keywords.
///
/// Every action returns an error sentence (for a snack bar) or null.
class ModelAnswersController extends AsyncNotifier<List<ModelAnswer>> {
  KnowledgeBaseRepository get _repository =>
      ref.read(knowledgeBaseRepositoryProvider);

  @override
  Future<List<ModelAnswer>> build() => ref
      .watch(knowledgeBaseRepositoryProvider)
      .answers(status: ref.watch(modelAnswerStatusProvider));

  /// Saves a new model answer; on success it is put at the top.
  Future<String?> create(NewModelAnswer answer) async {
    try {
      final row = await _repository.create(answer);
      if (!ref.mounted) return null;
      final filter = ref.read(modelAnswerStatusProvider);
      if (filter == null || filter == row.status) {
        state = AsyncData([row, ...?state.value]);
      }
      return null;
    } catch (e) {
      return ErrorMessages.of(e);
    }
  }

  Future<String?> setKeywords(
    String answerId,
    Map<String, List<String>> keywordsByPoint,
  ) async {
    try {
      final row = await _repository.setKeywords(answerId, keywordsByPoint);
      if (!ref.mounted) return null;
      state = AsyncData([
        for (final r in state.value ?? const <ModelAnswer>[])
          r.id == row.id ? row : r,
      ]);
      return null;
    } catch (e) {
      return ErrorMessages.of(e);
    }
  }
}

final modelAnswersProvider =
    AsyncNotifierProvider.autoDispose<
      ModelAnswersController,
      List<ModelAnswer>
    >(ModelAnswersController.new);

/// Structured + essay questions for the "Add model answer" form.
final writtenQuestionsProvider =
    FutureProvider.autoDispose<List<WrittenQuestion>>(
      (ref) => ref.watch(knowledgeBaseRepositoryProvider).writtenQuestions(),
    );
