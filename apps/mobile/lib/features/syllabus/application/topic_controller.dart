import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_repository.dart';
import '../domain/syllabus_models.dart';

part 'topic_controller.g.dart';

/// State for the Topic screen (Figma B4): the topic, its unit and whether
/// it is saved to "My library".
///
/// ```dart
/// final state = ref.watch(topicControllerProvider(topicId));
/// ```
@riverpod
class TopicController extends _$TopicController {
  @override
  Future<TopicDetail> build(String topicId) {
    return ref.watch(syllabusRepositoryProvider).fetchTopic(topicId);
  }

  /// Saves the topic to "My library", or removes it. Returns the new value.
  ///
  /// Updates the screen straight away and puts the old value back if the
  /// call fails (the error is rethrown so the screen can show it).
  Future<bool> toggleSaved() async {
    final current = state.value;
    if (current == null) return false;
    final saved = !current.saved;
    state = AsyncData(current.copyWith(saved: saved));
    try {
      await ref
          .read(syllabusRepositoryProvider)
          .setTopicSaved(topicId, saved: saved);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
    return saved;
  }
}
