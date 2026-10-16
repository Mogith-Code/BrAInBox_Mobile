import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, McqOption;

part 'practice_models.freezed.dart';
part 'practice_models.g.dart';

/// Placeholder model for the Practice feature.
///
// TODO(udith): replace these fields with the response of `GET /practice/hub`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class PracticeSummary with _$PracticeSummary {
  const factory PracticeSummary({
    required String title,
    @Default('') String message,
  }) = _PracticeSummary;

  factory PracticeSummary.fromJson(Map<String, dynamic> json) =>
      _$PracticeSummaryFromJson(json);
}
