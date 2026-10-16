import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/community_repository.dart';
import '../domain/community_models.dart';

part 'community_controller.g.dart';

/// State for the Community feature.
///
/// The state is an `AsyncValue<CommunitySummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(communityControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class CommunityController extends _$CommunityController {
  @override
  Future<CommunitySummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(communityRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
