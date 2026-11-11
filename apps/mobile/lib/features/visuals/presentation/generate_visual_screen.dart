import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/visuals_controller.dart';
import '../domain/visuals_models.dart';
import 'widgets/generate_widgets.dart';
import 'widgets/visual_widgets.dart';

/// Generate a visual (Figma B10): describe what you want, pick a type and a
/// style, then the AI makes it. While it works a moving loader shows
/// "Drawing your visual..."; when it's done the viewer opens on it.
///
/// Route: `/visuals/generate?topicId=...&prompt=...`. Both are optional:
/// students can draw anything, not only the topic they are on.
class GenerateVisualScreen extends ConsumerStatefulWidget {
  const GenerateVisualScreen({super.key, this.topicId, this.initialPrompt});

  final String? topicId;

  /// Fills in "What do you want to see?" (e.g. from a Home idea chip).
  final String? initialPrompt;

  @override
  ConsumerState<GenerateVisualScreen> createState() =>
      _GenerateVisualScreenState();
}

class _GenerateVisualScreenState extends ConsumerState<GenerateVisualScreen> {
  late final _prompt = TextEditingController(text: widget.initialPrompt);

  /// Shortest description we send (the backend also checks).
  static const minPromptLength = 5;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  bool get _canGenerate => _prompt.text.trim().length >= minPromptLength;

  void _generate() {
    FocusScope.of(context).unfocus();
    ref
        .read(generateVisualControllerProvider.notifier)
        .generate(prompt: _prompt.text, topicId: widget.topicId);
  }

  void _reset() {
    _prompt.clear();
    ref.read(generateVisualControllerProvider.notifier).reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateVisualControllerProvider);
    final controller = ref.read(generateVisualControllerProvider.notifier);

    // Done: open the new visual in place of this screen.
    ref.listen(generateVisualControllerProvider, (_, next) {
      final visual = next.visual;
      if (next.phase == GeneratePhase.done && visual != null) {
        context.pushReplacement(AppRoutes.diagramViewerPath(visual.id));
      }
    });

    if (state.isGenerating || state.phase == GeneratePhase.done) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _Generating(
            status: state.jobStatus,
            onCancel: controller.cancel,
          ),
        ),
      );
    }

    // Figma F7: the AI couldn't do it. "Not Biology" can't be fixed by
    // retrying, so that one sends the student back to change the text.
    if (state.phase == GeneratePhase.failed) {
      final notBiology = state.errorCode == 'NOT_BIOLOGY';
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: controller.cancel, // back to the form, text kept
          ),
        ),
        body: SafeArea(
          child: AiErrorState(
            title: notBiology
                ? 'That one is outside Biology'
                : "We couldn't draw your visual",
            message: state.error ?? ErrorMessages.generic,
            errorCode: state.errorCode,
            retryLabel: notBiology ? 'Change my description' : 'Try again',
            onRetry: notBiology || !_canGenerate
                ? controller.cancel
                : _generate,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final section = textTheme.titleSmall?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Generate a visual'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  AppTextField(
                    label: 'What do you want to see?',
                    hint:
                        'e.g. How urine is formed, step by step through '
                        'the nephron',
                    controller: _prompt,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        widget.topicId == null
                            ? Icons.collections_outlined
                            : Icons.menu_book_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.topicId == null
                              ? 'Any Biology idea works. It is saved in My visuals.'
                              : 'Saved under this topic and in My visuals.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final type in VisualType.values)
                        ChoicePill(
                          label: type.label,
                          selected: type == state.visualType,
                          onTap: () => controller.setType(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Style', style: section),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final style in VisualStyle.values) ...[
                        if (style != VisualStyle.values.first)
                          const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StyleCard(
                            style: style,
                            selected: style == state.style,
                            onTap: () => controller.setStyle(style),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(child: Text('Preview', style: section)),
                      const AiBadge(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  VisualTypePreview(type: state.visualType),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${state.visualType.label} · ${state.style.label}. '
                    'AI visuals can contain errors, so report anything wrong.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                      onPressed: _reset,
                      child: const Icon(
                        Icons.restart_alt,
                        semanticLabel: 'Start over',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Generate visual',
                      icon: Icons.auto_awesome,
                      variant: AppButtonVariant.gradient,
                      onPressed: _canGenerate ? _generate : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The waiting screen while the GENERATE_VISUAL job runs. The backend
/// doesn't report real progress (only 0, then 1 when done), so the bar
/// just keeps moving (`progress: null`).
class _Generating extends StatelessWidget {
  const _Generating({required this.status, required this.onCancel});

  final AiJobStatus status;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AiGeneratingLoader(
                message: status == AiJobStatus.queued
                    ? 'Getting your visual ready...'
                    : 'Drawing your visual...',
              ),
            ),
          ),
          Text(
            'This usually takes 10 to 60 seconds.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
