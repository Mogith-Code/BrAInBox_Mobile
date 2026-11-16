import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../syllabus/application/topic_controller.dart';
import '../../syllabus/data/learn_repository.dart';

part 'library_controller.g.dart';

/// The Library: bookmarked topics and saved short notes.
@Riverpod(keepAlive: true)
class BookmarksController extends _$BookmarksController {
  @override
  Future<List<Bookmark>> build() =>
      ref.watch(learnRepositoryProvider).fetchBookmarks();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }

  /// Removes a topic bookmark straight away; puts it back if the call
  /// fails (the error is rethrown so the screen can show it).
  Future<void> remove(Bookmark bookmark) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final b in current)
        if (b != bookmark) b,
    ]);
    try {
      await ref.read(learnRepositoryProvider).removeBookmark(bookmark.topicId);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
    final topic = topicControllerProvider(bookmark.topicId);
    if (ref.mounted && ref.exists(topic)) {
      ref.read(topic.notifier).setSavedLocally(false);
    }
  }
}
