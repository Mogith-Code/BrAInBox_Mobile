import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/admin_errors.dart';

import '../data/evaluations_repository.dart';
import '../domain/evaluation_models.dart';

/// The accuracy card (all teacher-marked answers, not the period buttons).
final evaluationAccuracyProvider = FutureProvider.autoDispose<AccuracyReport>(
  (ref) => ref.watch(evaluationsRepositoryProvider).accuracy(),
);

/// The table's page and "only teacher-marked" switch.
class EvaluationQueryController extends Notifier<EvaluationQuery> {
  @override
  EvaluationQuery build() => const EvaluationQuery();

  void onlyManual(bool value) => state = EvaluationQuery(onlyManual: value);

  void page(int page) =>
      state = EvaluationQuery(page: page, onlyManual: state.onlyManual);
}

final evaluationQueryProvider =
    NotifierProvider.autoDispose<EvaluationQueryController, EvaluationQuery>(
      EvaluationQueryController.new,
    );

/// The evaluations table, and saving a teacher's marks.
class EvaluationsController extends AsyncNotifier<EvaluationPage> {
  @override
  Future<EvaluationPage> build() => ref
      .watch(evaluationsRepositoryProvider)
      .evaluations(ref.watch(evaluationQueryProvider));

  /// Saves [marks] for [id]. Returns an error sentence, or null when saved.
  /// The accuracy card is reloaded, because its numbers change.
  Future<String?> setManualMarks(String id, double marks) async {
    try {
      final row = await ref
          .read(evaluationsRepositoryProvider)
          .setManualMarks(id, marks);
      if (!ref.mounted) return null;
      final page = state.value;
      if (page != null) state = AsyncData(page.replace(row));
      ref.invalidate(evaluationAccuracyProvider);
      return null;
    } catch (e) {
      return adminErrorMessage(e);
    }
  }
}

final evaluationsProvider =
    AsyncNotifierProvider.autoDispose<EvaluationsController, EvaluationPage>(
      EvaluationsController.new,
    );
