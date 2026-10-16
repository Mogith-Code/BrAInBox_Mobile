import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/home_repository.dart';
import '../domain/home_models.dart';

part 'home_controller.g.dart';

/// State for the Home feature.
///
/// The state is an `AsyncValue<HomeSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(homeControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(homeRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
