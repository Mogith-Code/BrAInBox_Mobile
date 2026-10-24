import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/diagnostic_controller.dart';
import '../domain/diagnostic_models.dart';

/// Diagnostic question (not in Figma - built in the style of the other
/// screens): progress "7/15", unit tag, question, options A-E, Next.
///
/// Route: `/diagnostic/questions`. Each answer is saved before moving on.
/// No right / wrong feedback during the diagnostic.
class DiagnosticQuestionScreen extends ConsumerStatefulWidget {
  const DiagnosticQuestionScreen({super.key});

  @override
  ConsumerState<DiagnosticQuestionScreen> createState() =>
      _DiagnosticQuestionScreenState();
}

class _DiagnosticQuestionScreenState
    extends ConsumerState<DiagnosticQuestionScreen> {
  @override
  void initState() {
    super.initState();
    // Opened directly (app restarted on this screen): load the attempt.
    if (ref.read(diagnosticControllerProvider).attempt == null) {
      Future.microtask(
        () => ref.read(diagnosticControllerProvider.notifier).start(),
      );
    }
  }

  Future<void> _next() async {
    final result = await ref.read(diagnosticControllerProvider.notifier).next();
    if (result != null && mounted) context.go(AppRoutes.diagnosticResult);
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(diagnosticControllerProvider);
    final controller = ref.read(diagnosticControllerProvider.notifier);
    final question = run.question;
    final textTheme = Theme.of(context).textTheme;

    if (question == null) {
      return Scaffold(
        body: Center(
          child: run.error != null
              ? ErrorBanner(message: run.error!, onRetry: controller.start)
              : const CircularProgressIndicator(),
        ),
      );
    }

    final number = run.index + 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close + progress "7/15"
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close (your answers are saved)',
                    onPressed: () => context.go(AppRoutes.diagnostic),
                    icon: const Icon(Icons.close),
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Semantics(
                      label: 'Question $number of ${run.total}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: run.total == 0 ? 0 : number / run.total,
                          minHeight: 6,
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ExcludeSemantics(
                    child: Text(
                      '$number/${run.total}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppChip(
                      icon: Icons.bookmark_outline,
                      label:
                          '${unitLabelFor(question.unitCode)} · '
                          '${question.unitTitle}',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        question.stem,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final option in question.options) ...[
                      McqOptionTile(
                        letter: option.label,
                        text: option.text,
                        state: run.picked == option.id
                            ? McqOptionState.selected
                            : McqOptionState.normal,
                        onTap: run.busy
                            ? null
                            : () => controller.pick(option.id),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  if (run.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        run.error!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  AppButton(
                    label: run.isLast ? 'See my results' : 'Next',
                    trailingIcon: Icons.arrow_forward,
                    isLoading: run.busy,
                    onPressed: run.picked == null ? null : _next,
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
