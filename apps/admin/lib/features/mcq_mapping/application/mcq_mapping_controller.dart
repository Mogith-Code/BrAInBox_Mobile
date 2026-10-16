import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mcq_mapping_repository.dart';
import '../domain/mcq_mapping_models.dart';

part 'mcq_mapping_controller.g.dart';

/// State for the McqMapping feature.
///
/// The state is an `AsyncValue<McqMappingSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(mcqMappingControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class McqMappingController extends _$McqMappingController {
  @override
  Future<McqMappingSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(mcqMappingRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(mcqMappingRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
