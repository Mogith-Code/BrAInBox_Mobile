import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show CommunityPost;

part 'community_models.freezed.dart';
part 'community_models.g.dart';

/// Placeholder model for the Community feature.
///
// TODO(mogith): replace these fields with the response of `GET /groups`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class CommunitySummary with _$CommunitySummary {
  const factory CommunitySummary({
    required String title,
    @Default('') String message,
  }) = _CommunitySummary;

  factory CommunitySummary.fromJson(Map<String, dynamic> json) =>
      _$CommunitySummaryFromJson(json);
}
