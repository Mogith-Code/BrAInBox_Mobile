import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';

import 'learn_repository.dart';

/// [LearnRepository] on the real backend: `{API_BASE_URL}/learn/...`.
///
/// The auth token, the 401 token refresh and the offline banner come from
/// [ApiClient]. Lists arrive as `{items: [], total}` (a bare list works too).
class ApiLearnRepository implements LearnRepository {
  ApiLearnRepository(this.api);

  final ApiClient api;

  static const _base = '/learn';

  @override
  Future<List<Subject>> fetchSubjects() async =>
      _items(await api.get<Object?>('$_base/subjects'), Subject.fromJson);

  @override
  Future<List<UnitProgress>> fetchUnits(String subjectId) async {
    final units = _items(
      await api.get<Object?>('$_base/subjects/$subjectId/units'),
      UnitProgress.fromJson,
    );
    return units..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<UnitDetail> fetchUnit(String unitId) async => UnitDetail.fromApi(
    await api.get<Map<String, dynamic>>('$_base/units/$unitId'),
  );

  @override
  Future<TopicDetail> fetchTopic(String topicId) async => TopicDetail.fromApi(
    await api.get<Map<String, dynamic>>('$_base/topics/$topicId'),
  );

  @override
  Future<TopicNote?> fetchNote(String topicId, NoteType type) async {
    try {
      final json = await api.get<Map<String, dynamic>>(
        '$_base/topics/$topicId/notes',
        query: {'type': type.name},
      );
      return TopicNote.fromJson(json);
    } on ApiException catch (e) {
      if (e.isNotFound) return null; // no notes yet
      rethrow;
    }
  }

  @override
  Future<String> startNoteGeneration(
    String topicId,
    NoteGenerationRequest request,
  ) async {
    final json = await api.post<Map<String, dynamic>>(
      '$_base/topics/$topicId/notes/generate',
      data: request.toJson(),
    );
    return '${json['job_id']}';
  }

  @override
  Future<GenerationJob> fetchJob(String jobId) async => GenerationJob.fromJson(
    await api.get<Map<String, dynamic>>('$_base/jobs/$jobId'),
  );

  @override
  Future<List<Diagram>> fetchDiagrams(String topicId) async => _items(
    await api.get<Object?>('$_base/topics/$topicId/diagrams'),
    Diagram.fromJson,
  );

  @override
  Future<List<Video>> fetchVideos(String topicId) async => _items(
    await api.get<Object?>('$_base/topics/$topicId/videos'),
    Video.fromJson,
  );

  @override
  Future<PracticeSummary> fetchPracticeSummary(String topicId) async =>
      PracticeSummary.fromJson(
        await api.get<Map<String, dynamic>>(
          '$_base/topics/$topicId/practice-summary',
        ),
      );

  @override
  Future<void> sendProgress(
    String topicId,
    ProgressEvent event, {
    int seconds = 0,
    bool completed = false,
  }) => api.post<Object?>(
    '$_base/topics/$topicId/progress',
    data: {'event': event.name, 'seconds': seconds, 'completed': completed},
  );

  @override
  Future<List<Bookmark>> fetchBookmarks() async =>
      _items(await api.get<Object?>('$_base/bookmarks'), Bookmark.fromJson);

  @override
  Future<void> addBookmark(String topicId) =>
      api.post<Object?>('$_base/bookmarks/$topicId');

  @override
  Future<void> removeBookmark(String topicId) =>
      api.delete<Object?>('$_base/bookmarks/$topicId');

  @override
  Future<SearchResult> search(String query) async {
    final json = await api.get<Map<String, dynamic>>(
      '$_base/search',
      query: {'q': query},
    );
    return SearchResult.fromJson(json);
  }

  @override
  Future<Upload> createUpload(
    PickedUploadFile file, {
    String? topicId,
    SummaryLength summaryLength = SummaryLength.medium,
    void Function(double progress)? onProgress,
  }) async {
    final part = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : await MultipartFile.fromFile(file.path!, filename: file.name);
    final json = await api.upload<Map<String, dynamic>>(
      '$_base/uploads',
      formData: FormData.fromMap({
        'file': part,
        'topic_id': ?topicId,
        'summary_length': summaryLength.name,
      }),
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    // The reply is `{upload_id, status}`; fill in what we already know.
    return Upload.fromJson({'file_name': file.name, ...json});
  }

  @override
  Future<List<Upload>> fetchUploads() async =>
      _items(await api.get<Object?>('$_base/uploads'), Upload.fromJson);

  @override
  Future<Upload> fetchUpload(String uploadId) async => Upload.fromJson(
    await api.get<Map<String, dynamic>>('$_base/uploads/$uploadId'),
  );

  @override
  Future<void> saveUploadToShortNotes(String uploadId) =>
      api.post<Object?>('$_base/uploads/$uploadId/save-to-short-notes');

  @override
  Future<void> deleteUpload(String uploadId) =>
      api.delete<Object?>('$_base/uploads/$uploadId');

  /// `{items: [...], total}` or a bare list -> models.
  static List<T> _items<T>(
    Object? body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = switch (body) {
      {'items': final List<dynamic> items} => items,
      final List<dynamic> items => items,
      _ => const <dynamic>[],
    };
    return [
      for (final item in list)
        if (item is Map) fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
