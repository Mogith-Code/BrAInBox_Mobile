import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Mistake, Topic;

part 'insights_models.freezed.dart';
part 'insights_models.g.dart';

/// Placeholder model for the Insights feature.
///
// TODO(keshomigha): replace these fields with the response of `GET /insights/mastery`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class InsightsSummary with _$InsightsSummary {
  const factory InsightsSummary({
    required String title,
    @Default('') String message,
  }) = _InsightsSummary;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      _$InsightsSummaryFromJson(json);
}
