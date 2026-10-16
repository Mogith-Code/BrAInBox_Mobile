import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/ai_job.dart';
import 'api_client.dart';
import 'api_exception.dart';

part 'job_poller.g.dart';

/// Waits for slow AI work (notes, visuals, paper generation, evaluation).
///
/// The backend starts the work and returns a job id right away. We then
/// poll `GET /jobs/{id}` until the job has `succeeded` or `failed`.
///
/// ```dart
/// final job = await ref.read(jobPollerProvider).waitFor(jobId);
/// ```
///
// TODO(samni): confirm the /jobs response shape with the backend /docs.
class JobPoller {
  JobPoller(
    this._api, {
    this.interval = const Duration(seconds: 2),
    this.timeout = const Duration(minutes: 3),
  });

  final ApiClient _api;

  /// Time between two polls.
  final Duration interval;

  /// Give up after this long.
  final Duration timeout;

  /// Emits the job every time it is polled, until it is done.
  /// Handy for progress bars (`job.progress`).
  Stream<AiJob> watch(String jobId) async* {
    final stopwatch = Stopwatch()..start();
    while (true) {
      final json = await _api.get<Map<String, dynamic>>('/jobs/$jobId');
      final job = AiJob.fromJson(json);
      yield job;
      if (job.isDone) return;
      if (stopwatch.elapsed > timeout) {
        throw const ApiException(
          code: 'job_timeout',
          message: 'The AI is taking longer than expected. Try again later.',
        );
      }
      await Future<void>.delayed(interval);
    }
  }

  /// Returns the finished job (succeeded or failed).
  Future<AiJob> waitFor(String jobId) => watch(jobId).last;
}

@riverpod
JobPoller jobPoller(Ref ref) => JobPoller(ref.watch(apiClientProvider));
