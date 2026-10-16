import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/visuals_repository.dart';
import '../domain/visuals_models.dart';

part 'visuals_controller.g.dart';

/// State for the Visuals feature.
///
/// The state is an `AsyncValue<VisualsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(visualsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class VisualsController extends _$VisualsController {
  @override
  Future<VisualsSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(visualsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(visualsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
