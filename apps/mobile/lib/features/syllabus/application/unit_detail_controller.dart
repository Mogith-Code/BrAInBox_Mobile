import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/learn_repository.dart';

part 'unit_detail_controller.g.dart';

/// State for the Unit detail screen: one unit and its topics. Kept in
/// memory; pull-to-refresh reloads.
///
/// ```dart
/// final state = ref.watch(unitDetailControllerProvider(unitId));
/// ```
@Riverpod(keepAlive: true)
class UnitDetailController extends _$UnitDetailController {
  @override
  Future<UnitDetail> build(String unitId) =>
      ref.watch(learnRepositoryProvider).fetchUnit(unitId);

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }

  /// Shows [topicId] as "In progress" right away once it is opened.
  void markInProgress(String topicId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        topics: [
          for (final t in current.topics)
            t.id == topicId && t.status == TopicStatus.notStarted
                ? t.copyWith(status: TopicStatus.inProgress)
                : t,
        ],
      ),
    );
  }
}
