import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, AiJob;

part 'evaluation_models.freezed.dart';
part 'evaluation_models.g.dart';

/// Placeholder model for the Evaluation feature.
///
// TODO(keshomigha): replace these fields with the response of `GET /evaluations/{evaluation_id}`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class EvaluationSummary with _$EvaluationSummary {
  const factory EvaluationSummary({
    required String title,
    @Default('') String message,
  }) = _EvaluationSummary;

  factory EvaluationSummary.fromJson(Map<String, dynamic> json) =>
      _$EvaluationSummaryFromJson(json);
}
