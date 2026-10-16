import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_models.freezed.dart';
part 'onboarding_models.g.dart';

/// Placeholder model for the Onboarding feature.
///
// TODO(mogith): replace these fields with what this feature needs
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class OnboardingSummary with _$OnboardingSummary {
  const factory OnboardingSummary({
    required String title,
    @Default('') String message,
  }) = _OnboardingSummary;

  factory OnboardingSummary.fromJson(Map<String, dynamic> json) =>
      _$OnboardingSummaryFromJson(json);
}
