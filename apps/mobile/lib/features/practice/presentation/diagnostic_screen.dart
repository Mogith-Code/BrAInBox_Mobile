import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/diagnostic_controller.dart';
import 'widgets/diagnostic_hero.dart';

/// "Let's find your starting point" (Figma A12) - the diagnostic intro.
///
/// Route: `/diagnostic`. Start diagnostic -> questions; Skip for now ->
/// Home (the Next best action card offers the diagnostic again later).
class DiagnosticIntroScreen extends ConsumerWidget {
  const DiagnosticIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(diagnosticControllerProvider);
    final controller = ref.read(diagnosticControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    Future<void> start() async {
      if (await controller.start() && context.mounted) {
        context.go(AppRoutes.diagnosticQuestions);
      }
    }

    Future<void> skip() async {
      if (await controller.skip() && context.mounted) {
        context.go(AppRoutes.home);
      }
    }

    // The bank doesn't have enough questions yet: let the student move on.
    if (run.notEnoughQuestions) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            title: "We're still adding questions",
            message: 'You can start learning now.',
            actionLabel: 'Start learning',
            onAction: run.busy ? null : skip,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DiagnosticHero(),
                    const SizedBox(height: AppSpacing.xl),
                    const ScreenHeading(
                      title: "Let's find your starting point",
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'A quick check across all 10 units so your plan starts '
                      "where you actually are. No pressure — it's not graded.",
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // TODO(udith): take these from the backend (start returns
                    // total + minutes) once there is a "preview" endpoint.
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.edit_outlined,
                            value: '15',
                            label: 'quick MCQs',
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatTile(
                            icon: Icons.schedule,
                            value: '~10',
                            label: 'minutes',
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatTile(
                            icon: Icons.bar_chart_rounded,
                            value: '10',
                            label: 'units',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
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
                    label: 'Start diagnostic',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.gradient,
                    isLoading: run.busy,
                    onPressed: start,
                  ),
                  TextButton(
                    onPressed: run.busy ? null : skip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Skip for now'),
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
