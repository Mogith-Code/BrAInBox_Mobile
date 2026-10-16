import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AppUser;

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// Placeholder model for the Profile feature.
///
// TODO(mogith): replace these fields with the response of `GET /me`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    required String title,
    @Default('') String message,
  }) = _ProfileSummary;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryFromJson(json);
}
