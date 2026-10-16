import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/recommendations_models.dart';

part 'recommendations_repository.g.dart';

/// Data layer for the Recommendations feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class RecommendationsRepository {
  RecommendationsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Recommendations screen.
  Future<RecommendationsSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/recommendations');
    // return RecommendationsSummary.fromJson(json);
    return const RecommendationsSummary(
      title: 'Next steps',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   GET /study-plan  ->  The student's study plan
  //   POST /reassessments  ->  Start a reassessment
}

@riverpod
RecommendationsRepository recommendationsRepository(Ref ref) =>
    RecommendationsRepository(ref.watch(apiClientProvider));
