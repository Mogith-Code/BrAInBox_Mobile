import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/insights_repository.dart';
import '../domain/insights_models.dart';

part 'insights_controller.g.dart';

/// State for the Insights feature.
///
/// The state is an `AsyncValue<InsightsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(insightsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class InsightsController extends _$InsightsController {
  @override
  Future<InsightsSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(insightsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(insightsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
