import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/insights_models.dart';

part 'insights_repository.g.dart';

/// Data layer for the Insights feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class InsightsRepository {
  InsightsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Insights screen.
  Future<InsightsSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/insights/mastery');
    // return InsightsSummary.fromJson(json);
    return const InsightsSummary(
      title: 'Insights',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   GET /insights/heatmap  ->  Heatmap data
  //   GET /mistakes  ->  Mistake journal entries
}

@riverpod
InsightsRepository insightsRepository(Ref ref) =>
    InsightsRepository(ref.watch(apiClientProvider));
