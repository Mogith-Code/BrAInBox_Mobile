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
/// style, then the AI makes it. While it works the pulsing loader shows the
/// job progress; when it's done the viewer opens on the new visual.
///
/// Route: `/visuals/generate?topicId=...` (the topic is optional).
class GenerateVisualScreen extends ConsumerStatefulWidget {
  const GenerateVisualScreen({super.key, this.topicId});

  final String? topicId;

  @override
  ConsumerState<GenerateVisualScreen> createState() =>
      _GenerateVisualScreenState();
}

class _GenerateVisualScreenState extends ConsumerState<GenerateVisualScreen> {
  final _prompt = TextEditingController();

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
            progress: state.progress,
            onCancel: controller.cancel,
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
                  if (state.phase == GeneratePhase.failed) ...[
                    ErrorBanner(
                      message: state.error ?? 'Something went wrong.',
                      onRetry: _canGenerate ? _generate : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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

/// The waiting screen while the GENERATE_VISUAL job runs.
class _Generating extends StatelessWidget {
  const _Generating({required this.progress, required this.onCancel});

  final double progress;
  final VoidCallback onCancel;

  static String messageFor(double progress) => switch (progress) {
    < 0.3 => 'Reading the syllabus...',
    < 0.6 => 'Drawing your visual...',
    _ => 'Adding the labels...',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AiGeneratingLoader(
                message: messageFor(progress),
                progress: progress > 0 ? progress : null,
              ),
            ),
          ),
          Text(
            'This usually takes under a minute.',
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
