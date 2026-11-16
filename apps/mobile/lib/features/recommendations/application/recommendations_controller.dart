import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendations_repository.dart';
import '../domain/recommendations_models.dart';

/// My next steps. Reload with `ref.invalidate(nextStepsProvider)`.
final nextStepsProvider = FutureProvider.autoDispose<NextSteps>(
  (ref) => ref.watch(recommendationsRepositoryProvider).fetchNextSteps(),
);

/// Before / after for one recommendation's concept.
final outcomeProvider = FutureProvider.autoDispose.family<Outcome, String>(
  (ref, id) => ref.watch(recommendationsRepositoryProvider).fetchOutcome(id),
);

/// The weekly study plan: tick, reorder, regenerate.
class StudyPlanController extends AsyncNotifier<StudyPlan> {
  RecommendationsRepository get _repository =>
      ref.read(recommendationsRepositoryProvider);

  @override
  Future<StudyPlan> build() =>
      ref.watch(recommendationsRepositoryProvider).fetchPlan();

  Future<void> regenerate() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_repository.regeneratePlan);
    if (ref.mounted) state = next;
  }

  /// Ticks / unticks an item. The tick shows at once and is undone if the
  /// server refuses it.
  Future<void> toggle(PlanItem item) async {
    final plan = state.value;
    if (plan == null) return;
    StudyPlan withItem(bool done) => plan.copyWithDays([
      for (final day in plan.days)
        day.copyWith(
          items: [
            for (final i in day.items)
              i.id == item.id ? i.copyWith(isDone: done) : i,
          ],
        ),
    ]);
    state = AsyncData(withItem(!item.isDone));
    try {
      await _repository.setItemDone(item.id, done: !item.isDone);
      ref.invalidate(nextStepsProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(withItem(item.isDone));
    }
  }

  /// Moves an item inside its day.
  Future<void> reorder(PlanDay day, int oldIndex, int newIndex) async {
    final plan = state.value;
    if (plan == null) return;
    final items = [...day.items];
    final moved = items.removeAt(oldIndex);
    // onReorderItem already gives the index in the list without the moved item.
    items.insert(newIndex.clamp(0, items.length), moved);
    state = AsyncData(
      plan.copyWithDays([
        for (final d in plan.days)
          d.date == day.date ? d.copyWith(items: items) : d,
      ]),
    );
    try {
      final saved = await _repository.reorder([for (final i in items) i.id]);
      if (ref.mounted) state = AsyncData(saved);
    } catch (_) {
      if (ref.mounted) state = AsyncData(plan);
    }
  }
}

final studyPlanProvider =
    AsyncNotifierProvider.autoDispose<StudyPlanController, StudyPlan>(
      StudyPlanController.new,
    );
