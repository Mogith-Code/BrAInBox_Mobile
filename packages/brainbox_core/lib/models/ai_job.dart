import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_job.freezed.dart';
part 'ai_job.g.dart';

enum AiJobStatus { queued, running, succeeded, failed, cancelled }

/// A long-running AI task on the backend (see JobPoller).
///
/// `GET /jobs/{id}` -> `{id, job_type, status, progress, result, error,
/// error_code, created_at, finished_at}`.
@freezed
abstract class AiJob with _$AiJob {
  const AiJob._();

  const factory AiJob({
    required String id,
    String? jobType, // "generate_visual", "generate_notes", ...
    @JsonKey(unknownEnumValue: AiJobStatus.queued)
    @Default(AiJobStatus.queued)
    AiJobStatus status,
    @Default(0) double progress, // 0.0 - 1.0 (some jobs only send 0 then 1)
    Map<String, dynamic>? result, // set when status == succeeded
    String? error, // set when failed: already a sentence for the student
    String? errorCode, // e.g. NOT_BIOLOGY, AI_DAILY_LIMIT
    DateTime? createdAt,
    DateTime? finishedAt,
  }) = _AiJob;

  factory AiJob.fromJson(Map<String, dynamic> json) => _$AiJobFromJson(json);

  bool get isDone =>
      status == AiJobStatus.succeeded ||
      status == AiJobStatus.failed ||
      status == AiJobStatus.cancelled;
}
