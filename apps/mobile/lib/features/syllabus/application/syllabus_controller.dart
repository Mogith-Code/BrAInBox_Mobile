import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/learn_repository.dart';

part 'syllabus_controller.g.dart';

/// Biology, Chemistry, Physics (`available` = has content). Cached for the
/// session.
@Riverpod(keepAlive: true)
Future<List<Subject>> subjects(Ref ref) =>
    ref.watch(learnRepositoryProvider).fetchSubjects();

/// State for the Learn screen: the units of the active subject (the first
/// available one, i.e. Biology). Kept in memory; pull-to-refresh reloads.
///
/// ```dart
/// final state = ref.watch(syllabusControllerProvider);
/// ```
@Riverpod(keepAlive: true)
class SyllabusController extends _$SyllabusController {
  @override
  Future<List<UnitProgress>> build() async {
    final subjects = await ref.watch(subjectsProvider.future);
    final active = subjects.where((s) => s.available).firstOrNull;
    if (active == null) return const [];
    return ref.watch(learnRepositoryProvider).fetchUnits(active.id);
  }

  /// Reloads subjects and units (pull-to-refresh). Keeps the old list on
  /// screen while loading.
  Future<void> refresh() async {
    ref.invalidate(subjectsProvider);
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }
}

/// Server-side search for units and topics. Empty for queries under 2
/// characters. The Learn screen debounces typing before reading this.
@riverpod
Future<SearchResult> learnSearch(Ref ref, String query) async {
  final q = query.trim();
  if (q.length < 2) return SearchResult.empty;
  return ref.watch(learnRepositoryProvider).search(q);
}
