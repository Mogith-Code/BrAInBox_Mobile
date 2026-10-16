import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Note, Visual;

part 'content_review_models.freezed.dart';
part 'content_review_models.g.dart';

/// Placeholder model for the ContentReview feature.
///
// TODO(samni): replace these fields with the response of `GET /admin/content?status=pending`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class ContentReviewSummary with _$ContentReviewSummary {
  const factory ContentReviewSummary({
    required String title,
    @Default('') String message,
  }) = _ContentReviewSummary;

  factory ContentReviewSummary.fromJson(Map<String, dynamic> json) =>
      _$ContentReviewSummaryFromJson(json);
}
