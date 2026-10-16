import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notes_repository.dart';
import '../domain/notes_models.dart';

part 'notes_controller.g.dart';

/// State for the Notes feature.
///
/// The state is an `AsyncValue<NotesSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(notesControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class NotesController extends _$NotesController {
  @override
  Future<NotesSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(notesRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(notesRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
