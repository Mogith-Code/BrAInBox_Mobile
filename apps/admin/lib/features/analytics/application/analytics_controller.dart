import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

part 'analytics_controller.g.dart';

/// The selected period (30 days by default, like the backend).
@riverpod
class AnalyticsRangeController extends _$AnalyticsRangeController {
  @override
  AnalyticsRange build() => AnalyticsRange.month;

  void set(AnalyticsRange range) => state = range;
}

/// Overview, performance and AI usage for the selected period.
@riverpod
Future<AnalyticsData> analytics(Ref ref) => ref
    .watch(analyticsRepositoryProvider)
    .load(ref.watch(analyticsRangeControllerProvider).days);
