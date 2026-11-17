import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';
import 'widgets/question_header.dart';

/// Type an answer to a structured / essay question and have it checked.
///
/// Route: `/evaluation/typed/:questionId`
class TypedAnswerScreen extends ConsumerStatefulWidget {
  const TypedAnswerScreen({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<TypedAnswerScreen> createState() => _TypedAnswerScreenState();
}

class _TypedAnswerScreenState extends ConsumerState<TypedAnswerScreen> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final id = await ref
        .read(evaluationSubmitProvider.notifier)
        .evaluate(questionId: widget.questionId, answerText: _answer.text);
    if (!mounted || id == null) return;
    context.pushReplacement(AppRoutes.evaluationFeedbackPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(evaluationSubmitProvider);
    if (submit.isBusy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checking your answer')),
        body: Center(
          child: AiGeneratingLoader(message: submit.message ?? 'Working...'),
        ),
      );
    }
    final words = _answer.text.trim().isEmpty
        ? 0
        : _answer.text.trim().split(RegExp(r'\s+')).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Type your answer')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          QuestionHeader(questionId: widget.questionId),
          const SizedBox(height: AppSpacing.lg),
          if (submit.errorMessage != null) ...[
            ErrorBanner(message: submit.errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _answer,
            minLines: 10,
            maxLines: 24,
            maxLength: 20000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write your answer here, as you would in the exam.',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$words word${words == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Check my answer',
            icon: Icons.fact_check_outlined,
            onPressed: words == 0 ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Photograph a handwritten answer instead',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.pushReplacement(
              AppRoutes.handwrittenUploadPath(widget.questionId),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Formative feedback – not an official exam mark.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
