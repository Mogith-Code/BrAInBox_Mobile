import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

part 'auth_controller.g.dart';

/// State for the Auth feature.
///
/// The state is an `AsyncValue<AuthSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(authControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<AuthSummary> build() {
    // TODO(mogith): load what the screen needs on open.
    return ref.watch(authRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(mogith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.

  /// Signs out. The router guard then sends the user to the login screen.
  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
