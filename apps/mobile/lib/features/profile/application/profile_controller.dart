import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

part 'profile_controller.g.dart';

/// State for the Profile feature.
///
/// The state is an `AsyncValue<ProfileSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(profileControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<ProfileSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(profileRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
