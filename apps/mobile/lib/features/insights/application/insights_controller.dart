import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/insights_repository.dart';
import '../domain/insights_models.dart';
import '../domain/insights_summary.dart';

part 'insights_controller.g.dart';

/// Insights failures are not retried automatically: a missing profile or a
/// forbidden attempt will not fix itself. The student taps Retry instead.
Duration? _noAutoRetry(int retryCount, Object error) => null;

/// Topic results for the Insights screens.
///
/// Pass [attemptId] to analyse a single attempt ("This attempt"); leave it
/// null to analyse every finished attempt.
/// ```dart
/// final state = ref.watch(insightsControllerProvider());
/// final one = ref.watch(insightsControllerProvider(attemptId: id));
/// ```
@Riverpod(retry: _noAutoRetry)
class InsightsController extends _$InsightsController {
  @override
  Future<TopicInsights> build({String? attemptId}) {
    return ref
        .watch(insightsRepositoryProvider)
        .fetchTopicInsights(attemptId: attemptId);
  }

  /// Reloads the data (pull-to-refresh, Retry button).
  ///
  /// Keeps the current data on screen while reloading (Riverpod keeps the
  /// previous value). If the reload fails, the error is in `state`, still
  /// together with the previous data, so this never throws.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Already in `state`; the screen shows it.
    }
  }
}

/// Mastery ring, study time, accuracy trend and unit mastery for one
/// [period] (`GET /insights/summary`).
/// ```dart
/// final state = ref.watch(
///   insightsSummaryControllerProvider(period: InsightsPeriod.week),
/// );
/// ```
@Riverpod(retry: _noAutoRetry)
class InsightsSummaryController extends _$InsightsSummaryController {
  @override
  Future<InsightsSummary> build({required InsightsPeriod period}) {
    return ref.watch(insightsRepositoryProvider).fetchSummary(period: period);
  }

  /// Reloads the data. Never throws; see [InsightsController.refresh].
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Already in `state`; the cards show it.
    }
  }
}
