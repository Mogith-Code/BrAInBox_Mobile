import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Placeholder model for the Dashboard feature.
///
// TODO(samni): replace these fields with the response of `GET /admin/dashboard`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required String title,
    @Default('') String message,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}
