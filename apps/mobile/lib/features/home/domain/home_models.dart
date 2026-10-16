import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Recommendation;

part 'home_models.freezed.dart';
part 'home_models.g.dart';

/// Placeholder model for the Home feature.
///
// TODO(samni): replace these fields with the response of `GET /home/summary`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    required String title,
    @Default('') String message,
  }) = _HomeSummary;

  factory HomeSummary.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryFromJson(json);
}
