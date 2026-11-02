import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/visuals_models.dart';
import 'fake_visuals_repository.dart';

part 'visuals_repository.g.dart';

/// Diagrams and AI visuals. Only this layer calls the API.
abstract interface class VisualsRepository {
  /// `GET /topics/{topic_id}/visuals` - approved visuals + the student's own.
  Future<TopicVisuals> topicVisuals(String topicId);

  /// `GET /visuals/{visual_id}`
  Future<Visual> visual(String visualId);

  /// `POST /visuals/generate` - starts a GENERATE_VISUAL job, returns its id.
  Future<String> startGeneration(GenerateVisualRequest request);

  /// The job every time it is polled (`GET /jobs/{id}`), until it is done.
  Stream<AiJob> watchJob(String jobId);

  /// The visual a succeeded job made. The job `result` holds either the
  /// whole visual (`{"visual": {...}}`) or just its id (`{"visual_id": ...}`).
  Future<Visual> visualFromJob(AiJob job);

  /// `POST /visuals/{visual_id}/report` with `{reason, details}`.
  Future<void> report(
    String visualId, {
    required VisualReportReason reason,
    String? details,
  });
}

class ApiVisualsRepository implements VisualsRepository {
  ApiVisualsRepository(this.api, this.poller);

  final ApiClient api;
  final JobPoller poller;

  @override
  Future<TopicVisuals> topicVisuals(String topicId) async =>
      TopicVisuals.fromJson(
        await api.get<Map<String, dynamic>>('/topics/$topicId/visuals'),
      );

  @override
  Future<Visual> visual(String visualId) async => Visual.fromJson(
    await api.get<Map<String, dynamic>>('/visuals/$visualId'),
  );

  @override
  Future<String> startGeneration(GenerateVisualRequest request) async {
    final json = await api.post<Map<String, dynamic>>(
      '/visuals/generate',
      data: request.toJson(),
    );
    return (json['job_id'] ?? json['id']) as String;
  }

  @override
  Stream<AiJob> watchJob(String jobId) => poller.watch(jobId);

  @override
  Future<Visual> visualFromJob(AiJob job) async {
    final result = job.result ?? const {};
    final inline = result['visual'];
    if (inline is Map<String, dynamic>) return Visual.fromJson(inline);
    final id = result['visual_id'];
    if (id is String) return visual(id);
    throw const ApiException(
      code: 'job_failed',
      message: 'The visual could not be made. Please try again.',
    );
  }

  @override
  Future<void> report(
    String visualId, {
    required VisualReportReason reason,
    String? details,
  }) => api.post<Object?>(
    '/visuals/$visualId/report',
    data: {
      'reason': reason.apiValue,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim(),
    },
  );
}

@Riverpod(keepAlive: true)
VisualsRepository visualsRepository(Ref ref) => Env.useFakeApi
    ? FakeVisualsRepository()
    : ApiVisualsRepository(
        ref.watch(apiClientProvider),
        ref.watch(jobPollerProvider),
      );
