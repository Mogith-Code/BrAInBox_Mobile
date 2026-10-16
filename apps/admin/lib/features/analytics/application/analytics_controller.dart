import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

part 'analytics_controller.g.dart';

/// State for the Analytics feature.
///
/// The state is an `AsyncValue<AnalyticsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(analyticsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class AnalyticsController extends _$AnalyticsController {
  @override
  Future<AnalyticsSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(analyticsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(analyticsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
