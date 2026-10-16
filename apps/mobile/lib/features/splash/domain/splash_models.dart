import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_models.freezed.dart';
part 'splash_models.g.dart';

/// Placeholder model for the Splash feature.
///
// TODO(mogith): replace these fields with what this feature needs
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class SplashSummary with _$SplashSummary {
  const factory SplashSummary({
    required String title,
    @Default('') String message,
  }) = _SplashSummary;

  factory SplashSummary.fromJson(Map<String, dynamic> json) =>
      _$SplashSummaryFromJson(json);
}
