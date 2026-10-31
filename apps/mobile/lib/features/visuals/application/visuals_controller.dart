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
    @Default(0) double progress, // 0.0 - 1.0 from the job
    Visual? visual, // set when phase == done
    String? error, // set when phase == failed
  }) = _GenerateVisualState;

  bool get isGenerating => phase == GeneratePhase.generating;
}

/// Generate a visual (Figma B10): start the GENERATE_VISUAL job, follow its
/// progress, then hand the new visual to the screen (which opens the viewer).
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
    state = state.copyWith(phase: GeneratePhase.editing, progress: 0);
  }

  Future<void> generate({required String prompt, String? topicId}) async {
    if (state.isGenerating || prompt.trim().isEmpty) return;
    final run = ++_run;
    state = state.copyWith(
      phase: GeneratePhase.generating,
      progress: 0,
      visual: null,
      error: null,
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
        state = state.copyWith(progress: job.progress);
      }
      if (last == null || last.status != AiJobStatus.succeeded) {
        throw ApiException(
          code: 'job_failed',
          message: last?.error ?? 'The visual could not be made.',
        );
      }
      final visual = await repo.visualFromJob(last);
      if (!ref.mounted || run != _run) return;
      state = state.copyWith(
        phase: GeneratePhase.done,
        progress: 1,
        visual: visual,
      );
      // The new visual should show up in the topic's gallery.
      if (topicId != null) ref.invalidate(topicVisualsControllerProvider);
    } catch (e) {
      if (!ref.mounted || run != _run) return;
      state = state.copyWith(
        phase: GeneratePhase.failed,
        error: e is ApiException && e.code == 'job_failed'
            ? e.message
            : ErrorMessages.of(e),
      );
    }
  }
}

/// "Report inaccuracy" (`POST /visuals/{id}/report`).
@riverpod
class VisualReportController extends _$VisualReportController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true when the report was sent.
  Future<bool> submit(
    String visualId, {
    required VisualReportReason reason,
    String? details,
  }) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref
          .read(visualsRepositoryProvider)
          .report(visualId, reason: reason, details: details),
    );
    if (ref.mounted) state = next;
    return !next.hasError;
  }
}
