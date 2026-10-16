import 'package:freezed_annotation/freezed_annotation.dart';

part 'past_papers_models.freezed.dart';
part 'past_papers_models.g.dart';

/// Placeholder model for the PastPapers feature.
///
// TODO(udith): replace these fields with the response of `GET /admin/past-papers`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class PastPapersSummary with _$PastPapersSummary {
  const factory PastPapersSummary({
    required String title,
    @Default('') String message,
  }) = _PastPapersSummary;

  factory PastPapersSummary.fromJson(Map<String, dynamic> json) =>
      _$PastPapersSummaryFromJson(json);
}
