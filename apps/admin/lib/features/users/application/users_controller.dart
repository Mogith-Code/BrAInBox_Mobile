import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/admin_errors.dart';

import '../data/users_repository.dart';
import '../domain/users_models.dart';

part 'users_controller.g.dart';

/// The search + filters above the Students table.
@riverpod
class StudentFilterController extends _$StudentFilterController {
  @override
  StudentFilter build() => const StudentFilter();

  /// Changing the search or a filter goes back to page 1.
  void set(StudentFilter filter) => state = filter.copyWith(page: 1);

  void page(int page) => state = state.copyWith(page: page);
}

/// The Students table for the current filter (`GET /admin/users`).
@riverpod
class UsersController extends _$UsersController {
  @override
  Future<StudentPage> build() => ref
      .watch(usersRepositoryProvider)
      .students(ref.watch(studentFilterControllerProvider));

  /// Suspends or reinstates a student. The row changes right away and goes
  /// back if the request fails. Returns why it failed, or null.
  Future<String?> setActive(String id, {required bool active}) async {
    final before = state.value;
    if (before == null) return 'The list is still loading.';
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
      return null;
    } catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return adminErrorMessage(e);
    }
  }
}

/// "Export CSV": every student matching the current search + filters (not
/// only the page on screen), read page by page from `GET /admin/users`.
class UsersCsvExport extends Notifier<AsyncValue<void>> {
  /// Safety stop: 1,000 pages of 100 students.
  static const _maxPages = 1000;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns the CSV and how many students it has, or throws.
  Future<({String csv, int count})> run() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(usersRepositoryProvider);
      final filter = ref.read(studentFilterControllerProvider);
      final rows = <AdminStudent>[];
      for (var page = 1; page <= _maxPages; page++) {
        final result = await repo.students(
          filter.copyWith(page: page),
          pageSize: StudentFilter.maxPageSize,
        );
        rows.addAll(result.items);
        if (result.items.length < StudentFilter.maxPageSize ||
            rows.length >= result.total) {
          break;
        }
      }
      if (ref.mounted) state = const AsyncData(null);
      return (csv: studentsCsv(rows), count: rows.length);
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }
}

final usersCsvExportProvider =
    NotifierProvider.autoDispose<UsersCsvExport, AsyncValue<void>>(
      UsersCsvExport.new,
    );
