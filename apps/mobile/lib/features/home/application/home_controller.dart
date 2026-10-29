import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/home_repository.dart';
import '../domain/home_models.dart';

part 'home_controller.g.dart';

/// The Home dashboard (`GET /home/summary`).
@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeSummary> build() => ref.watch(homeRepositoryProvider).summary();

  /// Pull-to-refresh: reloads but keeps showing the old data meanwhile.
  Future<void> refresh() async {
    final repo = ref.read(homeRepositoryProvider);
    final next = await AsyncValue.guard(repo.summary);
    if (ref.mounted) state = next;
  }

  /// Ticks / unticks a "Today's plan" item. Updates the screen right away
  /// (optimistic) and rolls back if `PATCH /home/plan/{id}` fails.
  /// Returns false when it had to roll back (the screen shows a message).
  Future<bool> togglePlanItem(String itemId) async {
    final before = state.value;
    if (before == null) return false;
    final item = before.todaysPlan.items
        .where((i) => i.id == itemId)
        .firstOrNull;
    if (item == null) return false;

    final repo = ref.read(homeRepositoryProvider);
    state = AsyncData(_withItemDone(before, itemId, !item.done));
    try {
      await repo.setPlanItemDone(itemId, done: !item.done);
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(before); // roll back
      return false;
    }
  }

  static HomeSummary _withItemDone(HomeSummary s, String id, bool done) {
    final items = [
      for (final i in s.todaysPlan.items)
        i.id == id ? i.copyWith(done: done) : i,
    ];
    return s.copyWith(
      todaysPlan: s.todaysPlan.copyWith(
        items: items,
        done: items.where((i) => i.done).length,
      ),
    );
  }
}
