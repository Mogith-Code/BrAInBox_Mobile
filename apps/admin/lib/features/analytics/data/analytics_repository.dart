import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/analytics_models.dart';

part 'analytics_repository.g.dart';

/// Data layer for the Analytics feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class AnalyticsRepository {
  AnalyticsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Analytics screen.
  Future<AnalyticsSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/analytics/most-missed-topics');
    // return AnalyticsSummary.fromJson(json);
    return const AnalyticsSummary(
      title: 'Analytics',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   GET /admin/analytics/misconceptions  ->  Most common misconceptions
}

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) =>
    AnalyticsRepository(ref.watch(apiClientProvider));
