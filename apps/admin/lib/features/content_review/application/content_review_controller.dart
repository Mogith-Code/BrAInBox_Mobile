import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/content_review_repository.dart';
import '../domain/content_review_models.dart';

part 'content_review_controller.g.dart';

/// State for the ContentReview feature.
///
/// The state is an `AsyncValue<ContentReviewSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(contentReviewControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class ContentReviewController extends _$ContentReviewController {
  @override
  Future<ContentReviewSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(contentReviewRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(contentReviewRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
