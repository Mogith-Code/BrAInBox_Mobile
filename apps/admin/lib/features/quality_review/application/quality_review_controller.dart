import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/admin_errors.dart';

import '../data/quality_review_repository.dart';
import '../domain/quality_review_models.dart';

part 'quality_review_controller.g.dart';

/// The quality queue. Approving / rejecting reloads it (the numbers at the
/// top change too). Every action returns why it failed, or null.
@riverpod
class QualityReviewController extends _$QualityReviewController {
  @override
  Future<QualityQueue> build() =>
      ref.watch(qualityReviewRepositoryProvider).queue();

  Future<String?> review(String id, {required bool approve}) =>
      reviewMany([id], approve: approve);

  /// "Approve all passing": every item whose checks all passed.
  Future<String?> approveAllPassing() async {
    final ids = [
      for (final i in state.value?.items ?? const <QualityItem>[])
        if (i.allPass) i.id,
    ];
    if (ids.isEmpty) return 'No question has passed every check.';
    return reviewMany(ids, approve: true);
  }

  Future<String?> reviewMany(List<String> ids, {required bool approve}) async {
    final repo = ref.read(qualityReviewRepositoryProvider);
    var done = 0;
    try {
      for (final id in ids) {
        await repo.review(id, approve: approve);
        done++;
      }
      return null;
    } catch (e) {
      final why = adminErrorMessage(e);
      return done == 0 ? why : '$done of ${ids.length} saved. $why';
    } finally {
      // Reload even after a partial failure: the saved ones left the queue.
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}
