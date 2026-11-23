import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../syllabus/data/learn_repository.dart';

part 'notes_controller.g.dart';

/// The notes of one type for a topic, or null when none exist yet.
///
/// ```dart
/// ref.watch(topicNoteProvider(topicId, NoteType.full));
/// ```
@riverpod
Future<TopicNote?> topicNote(Ref ref, String topicId, NoteType type) =>
    ref.watch(learnRepositoryProvider).fetchNote(topicId, type);

/// The government books for a topic and the page to open first.
@riverpod
Future<OfficialNotes> officialNotes(Ref ref, String topicId) =>
    ref.watch(learnRepositoryProvider).fetchOfficialNotes(topicId);

/// Keeps the most recently read book pages in memory, so scrolling back
/// doesn't download them again.
class OfficialPageCache {
  OfficialPageCache(this._repository);

  /// Small on purpose: scanned pages are large.
  static const maxPages = 12;

  final LearnRepository _repository;

  // A LinkedHashMap keeps insertion order, so the first key is the oldest.
  final _pages = <String, Uint8List>{};

  // Pages being downloaded, so one page is never requested twice at once.
  final _loading = <String, Future<Uint8List>>{};

  /// The page if it is already in memory.
  Uint8List? peek(String documentId, int page) => _pages['$documentId/$page'];

  /// The page from memory, or downloaded. A failed download isn't kept, so
  /// calling this again retries it.
  Future<Uint8List> load(String documentId, int page) {
    final key = '$documentId/$page';
    final cached = _pages.remove(key);
    if (cached != null) {
      _pages[key] = cached; // move to the "newest" end
      return Future.value(cached);
    }
    return _loading[key] ??= _repository
        .fetchOfficialPage(documentId, page)
        .then((bytes) {
          _pages[key] = bytes;
          if (_pages.length > maxPages) _pages.remove(_pages.keys.first);
          return bytes;
        })
        .whenComplete(() {
          // A block, not an arrow: returning the removed future here would
          // make this future wait for itself forever.
          _loading.remove(key);
        });
  }
}

/// One page cache for the whole app.
@Riverpod(keepAlive: true)
OfficialPageCache officialPageCache(Ref ref) =>
    OfficialPageCache(ref.watch(learnRepositoryProvider));

/// Where the Generate notes sheet is.
sealed class NoteGenerationState {
  const NoteGenerationState();
}

/// The form is showing.
class GenerationIdle extends NoteGenerationState {
  const GenerationIdle();
}

/// "BrAInBox is thinking": the job is queued or running.
class GenerationRunning extends NoteGenerationState {
  const GenerationRunning(this.status);

  final JobStatus status;
}

/// The notes are ready (the sheet closes and shows a toast).
class GenerationSucceeded extends NoteGenerationState {
  const GenerationSucceeded(this.noteId);

  final String? noteId;
}

/// Something went wrong; the sheet offers Retry.
class GenerationFailed extends NoteGenerationState {
  const GenerationFailed(this.message);

  final String message;
}

/// Starts note generation for a topic and polls the job until it is done.
@riverpod
class NoteGenerationController extends _$NoteGenerationController {
  /// Give up after this many polls (about 3 minutes at the default
  /// interval).
  static const maxPolls = 90;

  NoteGenerationRequest? _last;

  @override
  NoteGenerationState build(String topicId) => const GenerationIdle();

  bool get canRetry => _last != null;

  Future<void> generate(NoteGenerationRequest request) async {
    if (state is GenerationRunning) return;
    _last = request;
    state = const GenerationRunning(JobStatus.queued);
    final repository = ref.read(learnRepositoryProvider);
    final interval = ref.read(learnPollIntervalProvider);
    try {
      final jobId = await repository.startNoteGeneration(topicId, request);
      for (var i = 0; i < maxPolls; i++) {
        if (!ref.mounted) return;
        final job = await repository.fetchJob(jobId);
        if (!ref.mounted) return;
        switch (job.status) {
          case JobStatus.done:
            ref.invalidate(topicNoteProvider(topicId, request.type));
            state = GenerationSucceeded(job.resultId);
            return;
          case JobStatus.failed:
            state = GenerationFailed(
              job.error ?? "BrAInBox couldn't write these notes. Try again.",
            );
            return;
          case JobStatus.queued || JobStatus.running:
            state = GenerationRunning(job.status);
        }
        await Future<void>.delayed(interval);
      }
      if (ref.mounted) {
        state = const GenerationFailed(
          'This is taking longer than expected. Please try again later.',
        );
      }
    } catch (error) {
      if (ref.mounted) state = GenerationFailed(ErrorMessages.of(error));
    }
  }

  /// Runs the last request again.
  Future<void> retry() async {
    final last = _last;
    if (last == null) return reset();
    state = const GenerationIdle();
    await generate(last);
  }

  /// Back to the form.
  void reset() => state = const GenerationIdle();
}
