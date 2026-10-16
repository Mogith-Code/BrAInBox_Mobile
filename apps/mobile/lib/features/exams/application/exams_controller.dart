import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/exams_repository.dart';
import '../domain/exams_models.dart';

part 'exams_controller.g.dart';

/// State for the Exams feature.
///
/// The state is an `AsyncValue<ExamsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(examsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class ExamsController extends _$ExamsController {
  @override
  Future<ExamsSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(examsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(examsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
