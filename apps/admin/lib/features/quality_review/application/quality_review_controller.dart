import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/quality_review_repository.dart';
import '../domain/quality_review_models.dart';

part 'quality_review_controller.g.dart';

/// State for the QualityReview feature.
///
/// The state is an `AsyncValue<QualityReviewSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(qualityReviewControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class QualityReviewController extends _$QualityReviewController {
  @override
  Future<QualityReviewSummary> build() {
    // TODO(udith): load what the screen needs on open.
    return ref.watch(qualityReviewRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(qualityReviewRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(udith): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
