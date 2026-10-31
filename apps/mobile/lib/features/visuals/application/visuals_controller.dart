import 'package:brainbox_core/brainbox_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/visuals_repository.dart';
import '../domain/visuals_models.dart';

part 'visuals_controller.freezed.dart';
part 'visuals_controller.g.dart';

/// The diagram gallery of one topic (`GET /topics/{id}/visuals`).
@riverpod
class TopicVisualsController extends _$TopicVisualsController {
  @override
  Future<TopicVisuals> build(String topicId) =>
      ref.watch(visualsRepositoryProvider).topicVisuals(topicId);

  /// Pull-to-refresh: reloads but keeps showing the old grid meanwhile.
  Future<void> refresh() async {
    final repo = ref.read(visualsRepositoryProvider);
    final next = await AsyncValue.guard(() => repo.topicVisuals(topicId));
    if (ref.mounted) state = next;
  }
}

/// One visual for the viewer (`GET /visuals/{id}`).
@riverpod
Future<Visual> visualDetail(Ref ref, String visualId) =>
    ref.watch(visualsRepositoryProvider).visual(visualId);

enum GeneratePhase { editing, generating, done, failed }

/// What the Generate a visual screen shows. The prompt text itself lives in
/// the screen's text field.
@freezed
abstract class GenerateVisualState with _$GenerateVisualState {
  const GenerateVisualState._();

  const factory GenerateVisualState({
    @Default(GeneratePhase.editing) GeneratePhase phase,
    @Default(VisualType.process) VisualType visualType,
    @Default(VisualStyle.flatColour) VisualStyle style,
    // Where the backend job is. The backend only sends progress 0 then 1,
    // so the screen shows a moving (indeterminate) loader, not a % bar.
    @Default(AiJobStatus.queued) AiJobStatus jobStatus,
    Visual? visual, // set when phase == done
    String? error, // set when phase == failed: a sentence for the student
    String? errorCode, // e.g. NOT_BIOLOGY, AI_DAILY_LIMIT
  }) = _GenerateVisualState;

  bool get isGenerating => phase == GeneratePhase.generating;
}

/// Generate a visual (Figma B10): start the GENERATE_VISUAL job, poll it
/// (every 2 s, see JobPoller) and hand the new visual to the screen, which
/// opens the viewer. A real visual takes about 10-60 seconds.
@riverpod
class GenerateVisualController extends _$GenerateVisualController {
  /// Bumped by [cancel] so a running job's updates are ignored.
  int _run = 0;

  @override
  GenerateVisualState build() => const GenerateVisualState();

  void setType(VisualType type) => state = state.copyWith(visualType: type);

  void setStyle(VisualStyle style) => state = state.copyWith(style: style);

  /// Back to the defaults (the reset button).
  void reset() {
    _run++;
    state = const GenerateVisualState();
  }

  /// Stops waiting for the job (the backend may still finish it; the visual
  /// then shows up in the topic gallery).
  void cancel() {
    _run++;
    state = state.copyWith(phase: GeneratePhase.editing);
  }

  Future<void> generate({required String prompt, String? topicId}) async {
    if (state.isGenerating || prompt.trim().isEmpty) return;
    final run = ++_run;
    state = state.copyWith(
      phase: GeneratePhase.generating,
      jobStatus: AiJobStatus.queued,
      visual: null,
      error: null,
      errorCode: null,
    );
    final repo = ref.read(visualsRepositoryProvider);
    try {
      final jobId = await repo.startGeneration(
        GenerateVisualRequest(
          prompt: prompt.trim(),
          visualType: state.visualType,
          style: state.style,
          topicId: topicId,
        ),
      );
      AiJob? last;
      await for (final job in repo.watchJob(jobId)) {
        if (!ref.mounted || run != _run) return;
        last = job;
        state = state.copyWith(jobStatus: job.status);
      }
      if (last == null || last.status != AiJobStatus.succeeded) {
        if (!ref.mounted || run != _run) return;
        state = state.copyWith(
          phase: GeneratePhase.failed,
          error: _jobError(last),
          errorCode: last?.errorCode,
        );
        return;
      }
      final visual = await repo.visualFromJob(last);
      if (!ref.mounted || run != _run) return;
      state = state.copyWith(phase: GeneratePhase.done, visual: visual);
      // The new visual should show up in the topic's gallery.
      if (topicId != null) ref.invalidate(topicVisualsControllerProvider);
    } catch (e) {
      if (!ref.mounted || run != _run) return;
      state = state.copyWith(
        phase: GeneratePhase.failed,
        error: ErrorMessages.of(e),
        errorCode: e is ApiException ? e.code : null,
      );
    }
  }

  /// The backend's `error` is already written for the student, so it is
  /// shown as it is. Without one, the `error_code` picks the message.
  static String _jobError(AiJob? job) {
    if (job?.status == AiJobStatus.cancelled) {
      return 'This request was cancelled. Please try again.';
    }
    final text = job?.error;
    if (text != null && text.trim().isNotEmpty) return text;
    final code = job?.errorCode;
    return (code == null ? null : ErrorMessages.fromCode(code)) ??
        ErrorMessages.generic;
  }
}

/// "Report inaccuracy" (`POST /visuals/{id}/report`).
@riverpod
class VisualReportController extends _$VisualReportController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Sends the report. Returns the thank-you text to show, or null when it
  /// failed (the error is then in `state`).
  ///
  /// ALREADY_REPORTED (409) counts as success: the admin has it already.
  Future<String?> submit(
    String visualId, {
    required VisualReportReason reason,
    String? details,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(visualsRepositoryProvider)
          .report(visualId, reason: reason, details: details);
      if (ref.mounted) state = const AsyncData(null);
      return 'Thanks! An admin will check this visual.';
    } on ApiException catch (e) {
      if (e.code == 'ALREADY_REPORTED') {
        if (ref.mounted) state = const AsyncData(null);
        return ErrorMessages.fromApi(e);
      }
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return null;
    } catch (e, stack) {
      if (ref.mounted) state = AsyncError(e, stack);
      return null;
    }
  }
}
