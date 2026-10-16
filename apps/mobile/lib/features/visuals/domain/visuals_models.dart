import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Visual, AiJob;

part 'visuals_models.freezed.dart';
part 'visuals_models.g.dart';

/// Placeholder model for the Visuals feature.
///
// TODO(mogith): replace these fields with the response of `GET /topics/{topic_id}/visuals`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class VisualsSummary with _$VisualsSummary {
  const factory VisualsSummary({
    required String title,
    @Default('') String message,
  }) = _VisualsSummary;

  factory VisualsSummary.fromJson(Map<String, dynamic> json) =>
      _$VisualsSummaryFromJson(json);
}
