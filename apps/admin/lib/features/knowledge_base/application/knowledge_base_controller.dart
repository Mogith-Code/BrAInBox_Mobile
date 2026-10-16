import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/knowledge_base_repository.dart';
import '../domain/knowledge_base_models.dart';

part 'knowledge_base_controller.g.dart';

/// State for the KnowledgeBase feature.
///
/// The state is an `AsyncValue<KnowledgeBaseSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(knowledgeBaseControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class KnowledgeBaseController extends _$KnowledgeBaseController {
  @override
  Future<KnowledgeBaseSummary> build() {
    // TODO(keshomigha): load what the screen needs on open.
    return ref.watch(knowledgeBaseRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(knowledgeBaseRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(keshomigha): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
