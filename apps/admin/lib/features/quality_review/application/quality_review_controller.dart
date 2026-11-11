import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/quality_review_repository.dart';
import '../domain/quality_review_models.dart';

part 'quality_review_controller.g.dart';

/// The quality queue. Approving / rejecting reloads it (the numbers at the
/// top change too).
@riverpod
class QualityReviewController extends _$QualityReviewController {
  @override
  Future<QualityQueue> build() =>
      ref.watch(qualityReviewRepositoryProvider).queue();

  Future<bool> review(String id, {required bool approve}) =>
      reviewMany([id], approve: approve);

  /// "Approve all passing": every item whose checks all passed.
  Future<bool> approveAllPassing() {
    final ids = [
      for (final i in state.value?.items ?? const <QualityItem>[])
        if (i.allPass) i.id,
    ];
    return reviewMany(ids, approve: true);
  }

  Future<bool> reviewMany(List<String> ids, {required bool approve}) async {
    try {
      final repo = ref.read(qualityReviewRepositoryProvider);
      for (final id in ids) {
        await repo.review(id, approve: approve);
      }
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}
