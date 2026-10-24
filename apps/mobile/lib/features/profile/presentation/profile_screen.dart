import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/profile_setup_controller.dart';
import 'widgets/setup_steps.dart';

/// Profile setup, 3 steps (Figma A9-A11):
/// 1/3 What are you studying? · 2/3 Set your goal · 3/3 When can you study?
///
/// Route: `/profile/setup`. Resumes at the first unfinished step. The back
/// arrow (and Android back) goes to the previous step and keeps the values.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSetupControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ErrorBanner(
              message: ErrorMessages.of(error),
              onRetry: () => ref.invalidate(profileSetupControllerProvider),
            ),
          ),
          data: (s) => _SetupBody(state: s),
        ),
      ),
    );
  }
}

class _SetupBody extends ConsumerWidget {
  const _SetupBody({required this.state});

  final ProfileSetupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileSetupControllerProvider.notifier);
    final isLast = state.step == ProfileSetupState.steps - 1;
    final canGoBack = state.step > 0 || Navigator.canPop(context);

    void back() {
      if (!controller.back() && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    Future<void> next() async {
      final finished = await controller.next();
      // The redirect moves on too; this covers DISABLE_AUTH_GUARD runs.
      if (finished && context.mounted) context.go(AppRoutes.diagnostic);
    }

    final step = switch (state.step) {
      0 => StreamStep(
        state: state,
        onStream: controller.selectStream,
        onSubject: controller.selectSubject,
      ),
      1 => GoalStep(
        state: state,
        onYear: controller.setExamYear,
        onGrade: controller.setTargetGrade,
        onConfidence: controller.setConfidence,
      ),
      _ => AvailabilityStep(
        state: state,
        onDays: controller.setStudyDays,
        onHours: controller.setHoursPerDay,
        onTime: controller.setPreferredTime,
      ),
    };

    return PopScope(
      // Android back on steps 2-3 = previous step.
      canPop: state.step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: StepProgressHeader(
              step: state.step + 1,
              total: ProfileSetupState.steps,
              onBack: canGoBack ? back : null,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(state.step), child: step),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                    ),
                  ),
                AppButton(
                  label: isLast ? 'Finish setup' : 'Continue',
                  trailingIcon: Icons.arrow_forward,
                  isLoading: state.saving,
                  onPressed: state.stepComplete ? next : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
