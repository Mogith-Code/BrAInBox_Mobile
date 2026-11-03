import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_repository.dart';
import '../domain/syllabus_models.dart';

part 'syllabus_controller.g.dart';

/// State for the Learn screen: every unit with the student's mastery.
///
/// The state is an `AsyncValue<List<UnitProgress>>`, so the screen gets
/// loading, error and data cases for free:
/// ```dart
/// final state = ref.watch(syllabusControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class SyllabusController extends _$SyllabusController {
  @override
  Future<List<UnitProgress>> build() {
    return ref.watch(syllabusRepositoryProvider).fetchUnits();
  }

  /// Reloads the units (pull-to-refresh). Keeps the old list on screen
  /// while loading.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(syllabusRepositoryProvider).fetchUnits(),
    );
    if (ref.mounted) state = next;
  }
}
