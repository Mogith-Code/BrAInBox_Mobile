import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_models.freezed.dart';
part 'notifications_models.g.dart';

/// Placeholder model for the Notifications feature.
///
// TODO(samni): replace these fields with the response of `GET /notifications`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class NotificationsSummary with _$NotificationsSummary {
  const factory NotificationsSummary({
    required String title,
    @Default('') String message,
  }) = _NotificationsSummary;

  factory NotificationsSummary.fromJson(Map<String, dynamic> json) =>
      _$NotificationsSummaryFromJson(json);
}
