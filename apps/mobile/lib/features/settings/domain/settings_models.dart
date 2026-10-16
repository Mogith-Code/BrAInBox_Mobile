import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_models.freezed.dart';
part 'settings_models.g.dart';

/// Placeholder model for the Settings feature.
///
// TODO(samni): replace these fields with the response of `GET /me/settings`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class SettingsSummary with _$SettingsSummary {
  const factory SettingsSummary({
    required String title,
    @Default('') String message,
  }) = _SettingsSummary;

  factory SettingsSummary.fromJson(Map<String, dynamic> json) =>
      _$SettingsSummaryFromJson(json);
}
