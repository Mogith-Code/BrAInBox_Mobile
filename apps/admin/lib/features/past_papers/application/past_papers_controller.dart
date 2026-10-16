import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/past_papers_repository.dart';
import '../domain/past_papers_models.dart';

part 'past_papers_controller.g.dart';

/// State for the PastPapers feature.
///
/// The state is an `AsyncValue<PastPapersSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(pastPapersControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class PastPapersController extends _$PastPapersController {
  @override
  Future<PastPapersSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(pastPapersRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(pastPapersRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
