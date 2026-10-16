import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/recommendations_repository.dart';
import '../domain/recommendations_models.dart';

part 'recommendations_controller.g.dart';

/// State for the Recommendations feature.
///
/// The state is an `AsyncValue<RecommendationsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(recommendationsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class RecommendationsController extends _$RecommendationsController {
  @override
  Future<RecommendationsSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(recommendationsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(recommendationsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
