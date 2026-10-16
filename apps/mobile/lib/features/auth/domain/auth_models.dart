import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AppUser;

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Placeholder model for the Auth feature.
///
// TODO(mogith): replace these fields with the response of `GET /me`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class AuthSummary with _$AuthSummary {
  const factory AuthSummary({
    required String title,
    @Default('') String message,
  }) = _AuthSummary;

  factory AuthSummary.fromJson(Map<String, dynamic> json) =>
      _$AuthSummaryFromJson(json);
}
