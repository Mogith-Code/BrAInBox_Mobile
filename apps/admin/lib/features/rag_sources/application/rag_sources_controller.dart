import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/rag_sources_repository.dart';
import '../domain/rag_sources_models.dart';

part 'rag_sources_controller.g.dart';

/// State for the RagSources feature.
///
/// The state is an `AsyncValue<RagSourcesSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(ragSourcesControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class RagSourcesController extends _$RagSourcesController {
  @override
  Future<RagSourcesSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(ragSourcesRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(ragSourcesRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
