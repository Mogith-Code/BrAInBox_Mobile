import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

part 'auth_controller.g.dart';

/// The admin login form. `AsyncData(null)` = idle, `AsyncLoading` while
/// signing in, `AsyncError` with the reason it failed.
///
/// On success nothing else is needed here: `currentUserProvider` changes,
/// and the router guard opens the dashboard.
@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({
    required String email,
    required String password,
    bool keepSignedIn = true,
  }) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password, keepSignedIn: keepSignedIn),
    );
    if (ref.mounted) state = next.whenData((_) {});
  }

  /// Signs out. The router guard then sends the user to the login screen.
  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  /// The sentence to show under the form for [error].
  static String messageFor(Object error) => error is NotAdminException
      ? NotAdminException.message
      : ErrorMessages.of(error);
}
