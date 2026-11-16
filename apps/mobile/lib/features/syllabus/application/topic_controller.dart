import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../notes/application/library_controller.dart';
import '../data/learn_repository.dart';
import 'unit_detail_controller.dart';

part 'topic_controller.g.dart';

/// State for the Topic screen: the topic, its unit, mastery and whether it
/// is bookmarked. Kept in memory; pull-to-refresh reloads.
///
/// ```dart
/// final state = ref.watch(topicControllerProvider(topicId));
/// ```
@Riverpod(keepAlive: true)
class TopicController extends _$TopicController {
  @override
  Future<TopicDetail> build(String topicId) =>
      ref.watch(learnRepositoryProvider).fetchTopic(topicId);

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }

  /// Bookmarks the topic, or removes the bookmark. Returns the new value.
  ///
  /// Updates the screen straight away and puts the old value back if the
  /// call fails (the error is rethrown so the screen can show it).
  Future<bool> toggleSaved() async {
    final current = state.value;
    if (current == null) return false;
    final saved = !current.saved;
    state = AsyncData(current.copyWith(saved: saved));
    final repository = ref.read(learnRepositoryProvider);
    try {
      saved
          ? await repository.addBookmark(topicId)
          : await repository.removeBookmark(topicId);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
    if (ref.mounted) ref.invalidate(bookmarksControllerProvider);
    return saved;
  }

  /// Sets the bookmark flag without calling the server (the Library already
  /// did).
  void setSavedLocally(bool saved) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(saved: saved));
  }

  /// The topic was opened: tell the server (fire and forget) and show it as
  /// "In progress" if it was not started.
  Future<void> markOpened() async {
    final current = state.value;
    if (current == null) return;
    if (current.topic.status == TopicStatus.notStarted) {
      state = AsyncData(
        current.copyWith(
          topic: current.topic.copyWith(status: TopicStatus.inProgress),
        ),
      );
      final unit = unitDetailControllerProvider(current.unit.id);
      if (ref.exists(unit)) ref.read(unit.notifier).markInProgress(topicId);
    }
    try {
      await ref
          .read(learnRepositoryProvider)
          .sendProgress(topicId, ProgressEvent.opened);
    } catch (_) {
      // Progress is best effort; the next open sends it again.
    }
  }
}
