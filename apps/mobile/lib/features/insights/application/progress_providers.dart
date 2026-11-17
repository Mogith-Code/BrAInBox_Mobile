import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/insights_repository.dart';
import '../data/mistakes_repository.dart';
import '../domain/progress_models.dart';
import '../domain/recurring_mistakes.dart';

/// Failures are not retried automatically; the student taps Retry.
Duration? _noAutoRetry(int retryCount, Object error) => null;

/// Study time and accuracy trend (`GET /insights/overview`).
/// Reload with `ref.invalidate(insightsOverviewProvider)`.
final insightsOverviewProvider = FutureProvider.autoDispose<InsightsOverview>(
  (ref) => ref.watch(insightsRepositoryProvider).fetchOverview(),
  retry: _noAutoRetry,
);

/// Topic mastery map (`GET /insights/heatmap`).
final topicHeatmapProvider = FutureProvider.autoDispose<TopicHeatmap>(
  (ref) => ref.watch(insightsRepositoryProvider).fetchHeatmap(),
  retry: _noAutoRetry,
);

/// Misconceptions the student keeps hitting (`GET /mistakes/recurring`).
final recurringMistakesProvider = FutureProvider.autoDispose<RecurringMistakes>(
  (ref) => ref.watch(mistakesRepositoryProvider).recurring(),
  retry: _noAutoRetry,
);
