import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/upload_repository.dart';
import '../domain/upload_models.dart';

part 'upload_controller.g.dart';

/// State for the Upload feature.
///
/// The state is an `AsyncValue<UploadSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(uploadControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class UploadController extends _$UploadController {
  @override
  Future<UploadSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(uploadRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(uploadRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
