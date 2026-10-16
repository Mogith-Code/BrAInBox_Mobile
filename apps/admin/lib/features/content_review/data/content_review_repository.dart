import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/content_review_models.dart';

part 'content_review_repository.g.dart';

/// Data layer for the ContentReview feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ContentReviewRepository {
  ContentReviewRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main ContentReview screen.
  Future<ContentReviewSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/content');
    // return ContentReviewSummary.fromJson(json);
    return const ContentReviewSummary(
      title: 'Content review',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   PUT /admin/content/{content_id}  ->  Edit content
  //   POST /admin/content/{content_id}/approve  ->  Approve
  //   POST /admin/content/{content_id}/reject  ->  Reject with a reason
}

@riverpod
ContentReviewRepository contentReviewRepository(Ref ref) =>
    ContentReviewRepository(ref.watch(apiClientProvider));
