import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

part 'dashboard_controller.g.dart';

/// State for the Dashboard feature.
///
/// The state is an `AsyncValue<DashboardSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(dashboardControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class DashboardController extends _$DashboardController {
  @override
  Future<DashboardSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(dashboardRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
