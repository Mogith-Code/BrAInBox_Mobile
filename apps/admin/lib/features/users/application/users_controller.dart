import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/users_repository.dart';
import '../domain/users_models.dart';

part 'users_controller.g.dart';

/// The search + filters above the Students table.
@riverpod
class StudentFilterController extends _$StudentFilterController {
  @override
  StudentFilter build() => const StudentFilter();

  void set(StudentFilter filter) => state = filter;
}

/// The Students table for the current filter (`GET /admin/users`).
@riverpod
class UsersController extends _$UsersController {
  @override
  Future<StudentPage> build() => ref
      .watch(usersRepositoryProvider)
      .students(ref.watch(studentFilterControllerProvider));

  /// Suspends or reinstates a student. The row changes right away and goes
  /// back if the request fails. Returns false when it failed.
  Future<bool> setActive(String id, {required bool active}) async {
    final before = state.value;
    if (before == null) return false;
    AdminStudent swap(AdminStudent s) => s.id == id
        ? s.copyWith(
            status: active ? StudentStatus.active : StudentStatus.suspended,
          )
        : s;
    state = AsyncData(before.copyWith(items: before.items.map(swap).toList()));
    try {
      final saved = await ref
          .read(usersRepositoryProvider)
          .setActive(id, active: active);
      final now = state.value;
      if (ref.mounted && now != null) {
        state = AsyncData(
          now.copyWith(
            items: [for (final s in now.items) s.id == id ? saved : s],
          ),
        );
      }
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      return false;
    }
  }
}
