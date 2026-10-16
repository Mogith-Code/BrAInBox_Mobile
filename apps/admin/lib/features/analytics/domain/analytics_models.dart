import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Topic, Mistake;

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

/// Placeholder model for the Analytics feature.
///
// TODO(keshomigha): replace these fields with the response of `GET /admin/analytics/most-missed-topics`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class AnalyticsSummary with _$AnalyticsSummary {
  const factory AnalyticsSummary({
    required String title,
    @Default('') String message,
  }) = _AnalyticsSummary;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSummaryFromJson(json);
}
