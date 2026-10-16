import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_repository.dart';
import '../domain/syllabus_models.dart';

part 'syllabus_controller.g.dart';

/// State for the Syllabus feature.
///
/// The state is an `AsyncValue<SyllabusSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(syllabusControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class SyllabusController extends _$SyllabusController {
  @override
  Future<SyllabusSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(syllabusRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(syllabusRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
