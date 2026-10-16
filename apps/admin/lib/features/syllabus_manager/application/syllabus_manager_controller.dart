import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_manager_repository.dart';
import '../domain/syllabus_manager_models.dart';

part 'syllabus_manager_controller.g.dart';

/// State for the SyllabusManager feature.
///
/// The state is an `AsyncValue<SyllabusManagerSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(syllabusManagerControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class SyllabusManagerController extends _$SyllabusManagerController {
  @override
  Future<SyllabusManagerSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(syllabusManagerRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(syllabusManagerRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
