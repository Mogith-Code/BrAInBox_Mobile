import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';
import '../domain/evaluation_models.dart';

/// The text read from the photos. The student corrects any misread words
/// before the answer is checked.
///
/// Route: `/evaluation/ocr-preview?evaluationId=...`
class OcrPreviewScreen extends ConsumerWidget {
  const OcrPreviewScreen({super.key, this.evaluationId});

  final String? evaluationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = evaluationId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check the text')),
        body: EmptyState(
          title: 'Nothing to check yet',
          message: 'Photograph a handwritten answer first.',
          actionLabel: 'Choose a question',
          onAction: () => context.pushReplacement(AppRoutes.writtenQuestions),
        ),
      );
    }
    final submit = ref.watch(evaluationSubmitProvider);
    if (submit.isBusy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checking your answer')),
        body: Center(
          child: AiGeneratingLoader(message: submit.message ?? 'Working...'),
        ),
      );
    }
    final state = ref.watch(evaluationProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Check the text')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(evaluationProvider(id)),
          ),
        ),
        data: (evaluation) =>
            _Editor(evaluation: evaluation, error: submit.errorMessage),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.evaluation, this.error});

  final Evaluation evaluation;
  final String? error;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _text = TextEditingController(
    text: widget.evaluation.ocrText ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final evaluation = widget.evaluation;
    final id = await ref
        .read(evaluationSubmitProvider.notifier)
        .evaluate(
          questionId: evaluation.questionId,
          answerText: _text.text,
          evaluationId: evaluation.id,
        );
    if (!mounted || id == null) return;
    context.pushReplacement(AppRoutes.evaluationFeedbackPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evaluation = widget.evaluation;
    if (evaluation.isMarked) {
      // Already checked (e.g. the student came back): show the result.
      return EmptyState(
        title: 'This answer is already checked',
        actionLabel: 'See the feedback',
        onAction: () => context.pushReplacement(
          AppRoutes.evaluationFeedbackPath(evaluation.id),
        ),
      );
    }
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(evaluation.question, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            border: Border.all(color: AppColors.warningBorder),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Row(
            children: [
              Icon(Icons.spellcheck, color: AppColors.warningDark),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'This is what we read from your photos. Fix any words that '
                  'were read wrongly, so you are marked on what you wrote.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.error != null) ...[
          ErrorBanner(message: widget.error!),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: _text,
          minLines: 10,
          maxLines: 28,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Looks right, check my answer',
          icon: Icons.fact_check_outlined,
          onPressed: _text.text.trim().isEmpty ? null : _submit,
        ),
      ],
    );
  }
}
