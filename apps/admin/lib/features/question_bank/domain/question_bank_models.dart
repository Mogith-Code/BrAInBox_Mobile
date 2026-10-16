import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, McqOption;

part 'question_bank_models.freezed.dart';
part 'question_bank_models.g.dart';

/// Placeholder model for the QuestionBank feature.
///
// TODO(udith): replace these fields with the response of `GET /admin/questions`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class QuestionBankSummary with _$QuestionBankSummary {
  const factory QuestionBankSummary({
    required String title,
    @Default('') String message,
  }) = _QuestionBankSummary;

  factory QuestionBankSummary.fromJson(Map<String, dynamic> json) =>
      _$QuestionBankSummaryFromJson(json);
}
