import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/users_models.dart';

part 'users_repository.g.dart';

/// Data layer for the Users feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class UsersRepository {
  UsersRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Users screen.
  Future<UsersSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/users');
    // return UsersSummary.fromJson(json);
    return const UsersSummary(
      title: 'Users',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add one method per endpoint, e.g.
  //   POST /admin/users/{user_id}/suspend  ->  Suspend
  //   POST /admin/users/{user_id}/unsuspend  ->  Unsuspend
}

@riverpod
UsersRepository usersRepository(Ref ref) =>
    UsersRepository(ref.watch(apiClientProvider));
