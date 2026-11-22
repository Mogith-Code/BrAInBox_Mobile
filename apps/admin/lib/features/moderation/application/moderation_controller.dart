import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/admin_errors.dart';

import '../data/moderation_repository.dart';
import '../domain/moderation_models.dart';

part 'moderation_controller.g.dart';

/// The reports queue. Resolving a report removes it from the list at once
/// and puts it back if the request fails.
@riverpod
class ModerationController extends _$ModerationController {
  @override
  Future<List<ModerationItem>> build() =>
      ref.watch(moderationRepositoryProvider).reports();

  /// Returns why it failed (the screen shows it), or null.
  Future<String?> resolve(String id, ModerationAction action) async {
    final before = state.value;
    if (before == null) return 'The queue is still loading.';
    state = AsyncData([...before.where((r) => r.id != id)]);
    try {
      await ref.read(moderationRepositoryProvider).resolve(id, action);
      return null;
    } catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return adminErrorMessage(e);
    }
  }
}

/// The study groups list.
@riverpod
class StudyGroupsController extends _$StudyGroupsController {
  @override
  Future<List<StudyGroup>> build() =>
      ref.watch(moderationRepositoryProvider).groups();

  /// Returns why it failed, or null.
  Future<String?> create(String name) async {
    try {
      final group = await ref
          .read(moderationRepositoryProvider)
          .createGroup(name.trim());
      final now = state.value ?? const [];
      if (ref.mounted) state = AsyncData([...now, group]);
      return null;
    } catch (e) {
      return adminErrorMessage(e);
    }
  }
}
