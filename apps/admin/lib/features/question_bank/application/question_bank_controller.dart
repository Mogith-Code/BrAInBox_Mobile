import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/question_bank_repository.dart';
import '../domain/question_bank_models.dart';

part 'question_bank_controller.g.dart';

@riverpod
class QuestionFilterController extends _$QuestionFilterController {
  @override
  QuestionFilter build() => const QuestionFilter();

  /// Changing a filter goes back to page 1.
  void set(QuestionFilter filter) => state = filter.copyWith(page: 1);

  void page(int page) => state = state.copyWith(page: page);
}

/// The question bank table for the current filter and page.
@riverpod
class QuestionBankController extends _$QuestionBankController {
  @override
  Future<QuestionPage> build() => ref
      .watch(questionBankRepositoryProvider)
      .questions(ref.watch(questionFilterControllerProvider));

  /// Runs a bulk action on [ids], then reloads. Returns false on failure.
  Future<bool> bulk(List<String> ids, BulkAction action) async {
    try {
      await ref.read(questionBankRepositoryProvider).bulk(ids, action);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// One question for the editor (`GET /admin/questions/{id}`); 'new' gives
/// an empty MCQ.
@riverpod
Future<QuestionDetail> questionDetail(Ref ref, String id) => id == 'new'
    ? Future.value(QuestionDetail.blank())
    : ref.watch(questionBankRepositoryProvider).question(id);

/// Save draft / Publish.
@riverpod
class QuestionEditor extends _$QuestionEditor {
  @override
  AsyncValue<QuestionDetail?> build() => const AsyncData(null);

  Future<QuestionDetail?> save(
    QuestionDetail q, {
    required bool publish,
  }) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref
          .read(questionBankRepositoryProvider)
          .save(q.copyWith(status: publish ? 'approved' : 'draft')),
    );
    if (!ref.mounted) return null;
    state = next;
    if (next.hasValue) ref.invalidate(questionBankControllerProvider);
    return next.value;
  }
}
