import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_job.freezed.dart';
part 'ai_job.g.dart';

enum AiJobStatus { queued, running, succeeded, failed }

/// A long-running AI task on the backend (see JobPoller).
///
// TODO(samni): check these fields against the backend OpenAPI /docs.
@freezed
abstract class AiJob with _$AiJob {
  const AiJob._();

  const factory AiJob({
    required String id,
    @JsonKey(unknownEnumValue: AiJobStatus.queued)
    @Default(AiJobStatus.queued)
    AiJobStatus status,
    @Default(0) double progress, // 0.0 - 1.0
    Map<String, dynamic>? result, // set when status == succeeded
    String? error, // set when status == failed
  }) = _AiJob;

  factory AiJob.fromJson(Map<String, dynamic> json) => _$AiJobFromJson(json);

  bool get isDone =>
      status == AiJobStatus.succeeded || status == AiJobStatus.failed;
}
