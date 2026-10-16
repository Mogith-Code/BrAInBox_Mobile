import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AppUser;

part 'users_models.freezed.dart';
part 'users_models.g.dart';

/// Placeholder model for the Users feature.
///
// TODO(mogith): replace these fields with the response of `GET /admin/users`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class UsersSummary with _$UsersSummary {
  const factory UsersSummary({
    required String title,
    @Default('') String message,
  }) = _UsersSummary;

  factory UsersSummary.fromJson(Map<String, dynamic> json) =>
      _$UsersSummaryFromJson(json);
}
