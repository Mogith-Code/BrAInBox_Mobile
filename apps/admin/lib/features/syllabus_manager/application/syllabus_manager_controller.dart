import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_manager_repository.dart';
import '../domain/syllabus_manager_models.dart';

part 'syllabus_manager_controller.g.dart';

/// All units (`GET /admin/syllabus/units`, outdated included).
@riverpod
Future<List<AdminUnit>> syllabusUnits(Ref ref) =>
    ref.watch(syllabusManagerRepositoryProvider).units();

/// A unit's topics, loaded when the unit is opened in the tree.
@riverpod
Future<List<AdminTopic>> unitTopics(Ref ref, String unitId) =>
    ref.watch(syllabusManagerRepositoryProvider).topics(unitId);

/// A topic's concepts, loaded when the topic is opened in the tree.
@riverpod
Future<List<AdminConcept>> topicConcepts(Ref ref, String topicId) =>
    ref.watch(syllabusManagerRepositoryProvider).concepts(topicId);

/// Saving and adding nodes. After a change the right list reloads.
@riverpod
class SyllabusEditor extends _$SyllabusEditor {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Saves the edit form (only the fields the backend knows for [node]).
  Future<bool> save(
    SelectedNode node, {
    required String name,
    required String code,
    required String text,
    required bool isOutdated,
  }) => _run(() async {
    final fields = <String, dynamic>{
      ...switch (node.kind) {
        NodeKind.unit => {'title': name.trim(), 'description': text.trim()},
        NodeKind.topic => {
          'title': name.trim(),
          if (code.trim().isNotEmpty) 'number': code.trim(),
          'description': text.trim(),
        },
        NodeKind.concept => {
          'name': name.trim(),
          if (code.trim().isNotEmpty) 'code': code.trim(),
          'learning_outcome': text.trim(),
        },
      },
      'is_outdated': isOutdated,
    };
    await ref
        .read(syllabusManagerRepositoryProvider)
        .update(node.kind, node.id, fields);
    _reload(node.kind, node.parentId);
  });

  /// Adds a unit / topic / concept under [parentId].
  Future<bool> add(
    NodeKind kind, {
    required String parentId,
    required String name,
    required String code,
  }) => _run(() async {
    final fields = switch (kind) {
      NodeKind.unit => {'number': int.parse(code.trim()), 'title': name.trim()},
      NodeKind.topic => {'number': code.trim(), 'title': name.trim()},
      NodeKind.concept => {
        if (code.trim().isNotEmpty) 'code': code.trim(),
        'name': name.trim(),
      },
    };
    await ref
        .read(syllabusManagerRepositoryProvider)
        .create(kind, parentId: parentId, fields: fields);
    _reload(kind, parentId);
  });

  void _reload(NodeKind kind, String parentId) {
    switch (kind) {
      case NodeKind.unit:
        ref.invalidate(syllabusUnitsProvider);
      case NodeKind.topic:
        ref.invalidate(unitTopicsProvider(parentId));
        ref.invalidate(syllabusUnitsProvider); // topic counts
      case NodeKind.concept:
        ref.invalidate(topicConceptsProvider(parentId));
    }
  }

  Future<bool> _run(Future<void> Function() body) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(body);
    if (ref.mounted) state = next;
    return !next.hasError;
  }
}
