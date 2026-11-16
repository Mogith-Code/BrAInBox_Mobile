import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/learn_models.dart';
import '../domain/syllabus_models.dart';
import 'api_learn_repository.dart';
import 'mock_learn_repository.dart';

export '../domain/learn_models.dart';
export '../domain/syllabus_models.dart';

part 'learn_repository.g.dart';

/// Learn tab settings.
abstract final class LearnConfig {
  static const bool _mockDefine = bool.fromEnvironment('USE_MOCK_LEARN');

  /// `--dart-define=USE_MOCK_LEARN=true` (or the app-wide
  /// `USE_FAKE_API=true`) runs the Learn tab on [MockLearnRepository], so it
  /// works without the backend. Debug builds only, like `USE_FAKE_API`.
  static bool get useMock => kDebugMode && (_mockDefine || Env.useFakeApi);
}

/// Everything the Learn tab needs from the backend
/// (`/api/v1/learn/...`, see `features/syllabus/README.md`).
///
/// Two implementations: [ApiLearnRepository] (real backend) and
/// [MockLearnRepository] (in-memory seed data). Controllers call this;
/// screens never do. Every method throws [ApiException] on failure.
abstract interface class LearnRepository {
  /// `GET /subjects`
  Future<List<Subject>> fetchSubjects();

  /// `GET /subjects/{subjectId}/units`, in syllabus order.
  Future<List<UnitProgress>> fetchUnits(String subjectId);

  /// `GET /units/{unitId}`
  Future<UnitDetail> fetchUnit(String unitId);

  /// `GET /topics/{topicId}`
  Future<TopicDetail> fetchTopic(String topicId);

  /// `GET /topics/{topicId}/notes?type=` - null when there are no notes
  /// yet (404).
  Future<TopicNote?> fetchNote(String topicId, NoteType type);

  /// `POST /topics/{topicId}/notes/generate` - returns the job id.
  Future<String> startNoteGeneration(
    String topicId,
    NoteGenerationRequest request,
  );

  /// `GET /jobs/{jobId}`
  Future<GenerationJob> fetchJob(String jobId);

  /// `GET /topics/{topicId}/diagrams`
  Future<List<Diagram>> fetchDiagrams(String topicId);

  /// `GET /topics/{topicId}/videos`
  Future<List<Video>> fetchVideos(String topicId);

  /// `GET /topics/{topicId}/practice-summary`
  Future<PracticeSummary> fetchPracticeSummary(String topicId);

  /// `POST /topics/{topicId}/progress`
  Future<void> sendProgress(
    String topicId,
    ProgressEvent event, {
    int seconds = 0,
    bool completed = false,
  });

  /// `GET /bookmarks`
  Future<List<Bookmark>> fetchBookmarks();

  /// `POST /bookmarks/{topicId}`
  Future<void> addBookmark(String topicId);

  /// `DELETE /bookmarks/{topicId}`
  Future<void> removeBookmark(String topicId);

  /// `GET /search?q=`
  Future<SearchResult> search(String query);

  /// `POST /uploads` (multipart). [onProgress] gets 0-1 while sending.
  Future<Upload> createUpload(
    PickedUploadFile file, {
    String? topicId,
    SummaryLength summaryLength = SummaryLength.medium,
    void Function(double progress)? onProgress,
  });

  /// `GET /uploads`, newest first.
  Future<List<Upload>> fetchUploads();

  /// `GET /uploads/{uploadId}`
  Future<Upload> fetchUpload(String uploadId);

  /// `POST /uploads/{uploadId}/save-to-short-notes`
  Future<void> saveUploadToShortNotes(String uploadId);

  /// `DELETE /uploads/{uploadId}`
  Future<void> deleteUpload(String uploadId);
}

/// One repository for the whole app, so the mock keeps its state (bookmarks,
/// uploads) between screens.
@Riverpod(keepAlive: true)
LearnRepository learnRepository(Ref ref) => LearnConfig.useMock
    ? MockLearnRepository()
    : ApiLearnRepository(ref.watch(apiClientProvider));

/// Time between two polls of a generation job or an upload. Tests set it
/// to zero.
@Riverpod(keepAlive: true)
Duration learnPollInterval(Ref ref) => const Duration(seconds: 2);
