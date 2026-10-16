import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/question_bank_repository.dart';
import '../domain/question_bank_models.dart';

part 'question_bank_controller.g.dart';

/// State for the QuestionBank feature.
///
/// The state is an `AsyncValue<QuestionBankSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(questionBankControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class QuestionBankController extends _$QuestionBankController {
  @override
  Future<QuestionBankSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(questionBankRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(questionBankRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
