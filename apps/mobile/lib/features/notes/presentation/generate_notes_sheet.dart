import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../syllabus/domain/learn_models.dart';
import '../../syllabus/domain/syllabus_models.dart';
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/notes_controller.dart';

/// Opens the Generate notes sheet. Shows a "Notes ready" toast when the
/// notes were generated. Returns true on success.
Future<bool> showGenerateNotesSheet(
  BuildContext context, {
  required TopicDetail detail,
  NoteType type = NoteType.full,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.learnSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (_) => GenerateNotesSheet(detail: detail, initialType: type),
  );
  if (done == true) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Notes ready')));
  }
  return done == true;
}

/// Depth, examples, past-paper tips, note type and Generate; then
/// "BrAInBox is thinking" while the job runs, or an error with Retry.
class GenerateNotesSheet extends ConsumerStatefulWidget {
  const GenerateNotesSheet({
    super.key,
    required this.detail,
    this.initialType = NoteType.full,
  });

  final TopicDetail detail;
  final NoteType initialType;

  @override
  ConsumerState<GenerateNotesSheet> createState() => _GenerateNotesSheetState();
}

class _GenerateNotesSheetState extends ConsumerState<GenerateNotesSheet> {
  NoteDepth _depth = NoteDepth.standard;
  bool _examples = true;
  bool _tips = true;
  late NoteType _type = widget.initialType;

  String get _topicId => widget.detail.topic.id;

  void _generate() {
    ref
        .read(noteGenerationControllerProvider(_topicId).notifier)
        .generate(
          NoteGenerationRequest(
            type: _type,
            depth: _depth,
            includeExamples: _examples,
            includePastPaperTips: _tips,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = noteGenerationControllerProvider(_topicId);
    ref.listen(provider, (_, next) {
      if (next is GenerationSucceeded) Navigator.of(context).pop(true);
    });
    final state = ref.watch(provider);
    final textTheme = Theme.of(context).textTheme;
    final detail = widget.detail;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Generate notes',
                            style: textTheme.titleLarge?.copyWith(
                              color: context.learnInk,
                            ),
                          ),
                        ),
                        Text(
                          '${detail.topic.title} · Unit ${detail.unit.order}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.learnMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (state) {
                  GenerationRunning(:final status) => Column(
                    key: const ValueKey('running'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AIThinkingCard(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        status == JobStatus.queued
                            ? 'Waiting for a free spot…'
                            : 'Writing your ${_type == NoteType.short ? 'short notes' : 'notes'}…',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.learnMuted,
                        ),
                      ),
                    ],
                  ),
                  GenerationFailed(:final message) => _ErrorPanel(
                    key: const ValueKey('error'),
                    message: message,
                    onRetry: () =>
                        ref.read(provider.notifier).retry(),
                    onChangeOptions: () => ref.read(provider.notifier).reset(),
                  ),
                  _ => _form(context),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Text label(String text) => Text(
      text,
      style: textTheme.labelLarge?.copyWith(color: context.learnInk),
    );

    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('Depth'),
        const SizedBox(height: AppSpacing.sm),
        for (final depth in NoteDepth.values) ...[
          _DepthCard(
            depth: depth,
            selected: depth == _depth,
            onTap: () => setState(() => _depth = depth),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: label('Include examples'),
          value: _examples,
          onChanged: (v) => setState(() => _examples = v),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: label('Include past-paper tips'),
          value: _tips,
          onChanged: (v) => setState(() => _tips = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        label('Note type'),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<NoteType>(
          segments: const [
            ButtonSegment(
              value: NoteType.full,
              label: Text('Full notes'),
              icon: Icon(Icons.article_outlined),
            ),
            ButtonSegment(
              value: NoteType.short,
              label: Text('Short notes'),
              icon: Icon(Icons.format_list_bulleted),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        GradientButton(label: 'Generate', onPressed: _generate),
      ],
    );
  }
}

class _DepthCard extends StatelessWidget {
  const _DepthCard({
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final NoteDepth depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(LearnStyle.buttonRadius);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${depth.label}, ${depth.readTime}',
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? (context.isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primarySoft)
              : context.learnSurface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? AppColors.primary : context.learnBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : context.learnMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        depth.label,
                        style: textTheme.titleSmall?.copyWith(
                          color: context.learnInk,
                        ),
                      ),
                    ),
                    Text(
                      depth.readTime,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.learnMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onChangeOptions,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChangeOptions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(LearnStyle.cardRadius),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.errorDark),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Couldn't generate notes",
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.errorDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onChangeOptions, child: const Text('Change options')),
        ],
      ),
    );
  }
}
