import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, AiJob;

part 'exams_models.freezed.dart';
part 'exams_models.g.dart';

/// Placeholder model for the Exams feature.
///
// TODO(udith): replace these fields with the response of `GET /past-papers`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class ExamsSummary with _$ExamsSummary {
  const factory ExamsSummary({
    required String title,
    @Default('') String message,
  }) = _ExamsSummary;

  factory ExamsSummary.fromJson(Map<String, dynamic> json) =>
      _$ExamsSummaryFromJson(json);
}
