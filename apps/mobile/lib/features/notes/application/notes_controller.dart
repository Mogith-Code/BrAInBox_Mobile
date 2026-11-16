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
