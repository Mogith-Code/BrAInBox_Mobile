import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_overview_repository.dart';
import '../domain/profile_overview_models.dart';

part 'profile_overview_controller.g.dart';

/// The Profile page (`GET /profile/overview`).
@riverpod
class ProfileOverviewController extends _$ProfileOverviewController {
  @override
  Future<ProfileOverview> build() =>
      ref.watch(profileOverviewRepositoryProvider).overview();

  /// After the "Achievement unlocked" pop-up: remember it was seen (so it
  /// shows only once) and update the list.
  Future<void> markSeen(String id) async {
    final before = state.value;
    if (before != null) {
      state = AsyncData(
        before.copyWith(
          achievements: [
            for (final a in before.achievements)
              a.id == id ? a.copyWith(seen: true) : a,
          ],
        ),
      );
    }
    try {
      await ref.read(profileOverviewRepositoryProvider).markSeen(id);
    } catch (_) {
      // Not critical: at worst the pop-up shows again next time.
    }
  }
}
