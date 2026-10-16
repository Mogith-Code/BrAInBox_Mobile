import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/users_repository.dart';
import '../domain/users_models.dart';

part 'users_controller.g.dart';

/// State for the Users feature.
///
/// The state is an `AsyncValue<UsersSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(usersControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class UsersController extends _$UsersController {
  @override
  Future<UsersSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(usersRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(usersRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
