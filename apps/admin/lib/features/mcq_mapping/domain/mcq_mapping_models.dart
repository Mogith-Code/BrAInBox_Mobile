import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, McqOption;

part 'mcq_mapping_models.freezed.dart';
part 'mcq_mapping_models.g.dart';

/// Placeholder model for the McqMapping feature.
///
// TODO(udith): replace these fields with the response of `GET /admin/questions/{question_id}`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class McqMappingSummary with _$McqMappingSummary {
  const factory McqMappingSummary({
    required String title,
    @Default('') String message,
  }) = _McqMappingSummary;

  factory McqMappingSummary.fromJson(Map<String, dynamic> json) =>
      _$McqMappingSummaryFromJson(json);
}
