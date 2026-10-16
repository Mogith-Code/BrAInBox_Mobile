import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show CommunityPost;

part 'moderation_models.freezed.dart';
part 'moderation_models.g.dart';

/// Placeholder model for the Moderation feature.
///
// TODO(mogith): replace these fields with the response of `GET /admin/reports`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class ModerationSummary with _$ModerationSummary {
  const factory ModerationSummary({
    required String title,
    @Default('') String message,
  }) = _ModerationSummary;

  factory ModerationSummary.fromJson(Map<String, dynamic> json) =>
      _$ModerationSummaryFromJson(json);
}
