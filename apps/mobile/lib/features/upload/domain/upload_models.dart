import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AiJob;

part 'upload_models.freezed.dart';
part 'upload_models.g.dart';

/// Placeholder model for the Upload feature.
///
// TODO(samni): replace these fields with the response of `GET /jobs/{job_id}`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class UploadSummary with _$UploadSummary {
  const factory UploadSummary({
    required String title,
    @Default('') String message,
  }) = _UploadSummary;

  factory UploadSummary.fromJson(Map<String, dynamic> json) =>
      _$UploadSummaryFromJson(json);
}
