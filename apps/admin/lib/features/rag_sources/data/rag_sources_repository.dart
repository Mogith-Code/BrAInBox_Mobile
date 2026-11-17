import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rag_sources_models.dart';

/// RAG source documents (admin). Only this layer calls the API.
abstract interface class RagSourcesRepository {
  /// `GET /admin/rag/sources` (last changed first).
  Future<List<RagSource>> sources();

  /// `POST /admin/rag/sources` (multipart) -> 202 with a RAG_INGEST job.
  Future<RagJob> upload(
    RagUpload form, {
    required String fileName,
    required List<int> bytes,
  });

  /// `POST /admin/rag/reindex` with `{document_id}`; null = every document.
  Future<RagJob> reindex({String? documentId});

  /// Waits for an ingest job to finish (`GET /jobs/{id}`).
  Future<AiJob> waitForJob(String jobId);
}

class ApiRagSourcesRepository implements RagSourcesRepository {
  ApiRagSourcesRepository(this.api, this.jobs);

  final ApiClient api;
  final JobPoller jobs;

  @override
  Future<List<RagSource>> sources() async => [
    for (final e in await api.get<List<dynamic>>('/admin/rag/sources'))
      RagSource.fromJson(Map<String, dynamic>.from(e as Map)),
  ];

  @override
  Future<RagJob> upload(
    RagUpload form, {
    required String fileName,
    required List<int> bytes,
  }) async => RagJob.fromJson(
    await api.uploadBytes<Map<String, dynamic>>(
      '/admin/rag/sources',
      bytes: bytes,
      fileName: fileName,
      fields: form.toFields(),
    ),
  );

  @override
  Future<RagJob> reindex({String? documentId}) async => RagJob.fromJson(
    await api.post<Map<String, dynamic>>(
      '/admin/rag/reindex',
      data: documentId == null ? null : {'document_id': documentId},
    ),
  );

  @override
  Future<AiJob> waitForJob(String jobId) => jobs.waitFor(jobId);
}

/// DEBUG ONLY (`USE_FAKE_API=true`), also used by the tests. Jobs finish at
/// once: an upload becomes "ready" with a few chunks.
class FakeRagSourcesRepository implements RagSourcesRepository {
  final reindexed = <String?>[];
  final uploads = <(RagUpload, String)>[];

  final _rows = <RagSource>[
    RagSource(
      id: 's1',
      title: 'A/L Biology syllabus (NIE, 2017 revision)',
      sourceType: 'syllabus',
      status: RagSourceStatus.ready,
      chunkCount: 412,
      pageCount: 64,
      indexedAt: DateTime(2026, 10, 1, 10),
      updatedAt: DateTime(2026, 10, 1, 10),
    ),
    RagSource(
      id: 's2',
      title: "Teacher's guide · Unit 6 Genetics",
      sourceType: 'teachers_guide',
      unitNumber: 6,
      status: RagSourceStatus.ingesting,
      chunkCount: 0,
      updatedAt: DateTime(2026, 10, 7, 9),
    ),
    RagSource(
      id: 's3',
      title: '2019 Paper II marking scheme',
      sourceType: 'marking_scheme',
      year: 2019,
      status: RagSourceStatus.failed,
      errorMessage: 'The PDF has no text layer (scanned pages).',
      updatedAt: DateTime(2026, 10, 6, 16),
    ),
  ];

  @override
  Future<List<RagSource>> sources() async => List.of(_rows);

  @override
  Future<RagJob> upload(
    RagUpload form, {
    required String fileName,
    required List<int> bytes,
  }) async {
    uploads.add((form, fileName));
    final id = 's${_rows.length + 1}';
    _rows.insert(
      0,
      RagSource(
        id: id,
        title: form.title,
        sourceType: form.type.apiValue,
        unitNumber: form.unitNumber,
        year: form.year,
        status: RagSourceStatus.ready,
        chunkCount: 12,
        pageCount: 3,
        indexedAt: DateTime(2026, 10, 7, 12),
        updatedAt: DateTime(2026, 10, 7, 12),
      ),
    );
    return RagJob(jobId: 'job-$id', documentId: id);
  }

  @override
  Future<RagJob> reindex({String? documentId}) async {
    if (documentId != null && !_rows.any((r) => r.id == documentId)) {
      throw const ApiException(
        code: 'SOURCE_NOT_FOUND',
        message: 'Source document not found',
        statusCode: 404,
      );
    }
    reindexed.add(documentId);
    return RagJob(jobId: 'job-reindex', documentId: documentId);
  }

  @override
  Future<AiJob> waitForJob(String jobId) async =>
      AiJob(id: jobId, status: AiJobStatus.succeeded, progress: 1);
}

final ragSourcesRepositoryProvider = Provider<RagSourcesRepository>(
  (ref) => Env.useFakeApi
      ? FakeRagSourcesRepository()
      : ApiRagSourcesRepository(
          ref.watch(apiClientProvider),
          ref.watch(jobPollerProvider),
        ),
);
