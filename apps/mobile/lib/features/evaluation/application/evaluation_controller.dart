import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/evaluation_repository.dart';
import '../domain/evaluation_models.dart';

part 'evaluation_controller.g.dart';

/// State for the Evaluation feature.
///
/// The state is an `AsyncValue<EvaluationSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(evaluationControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class EvaluationController extends _$EvaluationController {
  @override
  Future<EvaluationSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(evaluationRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(evaluationRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
