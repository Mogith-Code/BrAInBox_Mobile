import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/splash_repository.dart';
import '../domain/splash_models.dart';

part 'splash_controller.g.dart';

/// State for the Splash feature.
///
/// The state is an `AsyncValue<SplashSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(splashControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class SplashController extends _$SplashController {
  @override
  Future<SplashSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(splashRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(splashRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
