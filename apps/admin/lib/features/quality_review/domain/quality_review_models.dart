import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question;

part 'quality_review_models.freezed.dart';
part 'quality_review_models.g.dart';

/// Placeholder model for the QualityReview feature.
///
// TODO(udith): replace these fields with the response of `GET /admin/quality-checks`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class QualityReviewSummary with _$QualityReviewSummary {
  const factory QualityReviewSummary({
    required String title,
    @Default('') String message,
  }) = _QualityReviewSummary;

  factory QualityReviewSummary.fromJson(Map<String, dynamic> json) =>
      _$QualityReviewSummaryFromJson(json);
}
