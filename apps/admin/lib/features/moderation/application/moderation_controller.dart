import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/moderation_repository.dart';
import '../domain/moderation_models.dart';

part 'moderation_controller.g.dart';

/// State for the Moderation feature.
///
/// The state is an `AsyncValue<ModerationSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(moderationControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class ModerationController extends _$ModerationController {
  @override
  Future<ModerationSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(moderationRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(moderationRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
