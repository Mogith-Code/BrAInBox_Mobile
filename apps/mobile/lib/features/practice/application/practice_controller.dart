import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/practice_repository.dart';
import '../domain/practice_models.dart';

part 'practice_controller.g.dart';

/// State for the Practice feature.
///
/// The state is an `AsyncValue<PracticeSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(practiceControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class PracticeController extends _$PracticeController {
  @override
  Future<PracticeSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(practiceRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(practiceRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
