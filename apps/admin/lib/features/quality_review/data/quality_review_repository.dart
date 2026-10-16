import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/quality_review_models.dart';

part 'quality_review_repository.g.dart';

/// Data layer for the QualityReview feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class QualityReviewRepository {
  QualityReviewRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main QualityReview screen.
  Future<QualityReviewSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/quality-checks');
    // return QualityReviewSummary.fromJson(json);
    return const QualityReviewSummary(
      title: 'Quality review',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   POST /admin/quality-checks/{check_id}/resolve  ->  Accept / fix / discard
}

@riverpod
QualityReviewRepository qualityReviewRepository(Ref ref) =>
    QualityReviewRepository(ref.watch(apiClientProvider));
