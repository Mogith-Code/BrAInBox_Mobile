import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/recommendations_controller.dart';
import '../data/recommendations_repository.dart';
import '../domain/recommendations_models.dart';

/// Reassessment result: mastery of the concept before and after, with a
/// small celebration when it went up.
///
/// Route: `/recommendations/reassessment?id=<recommendation id>`
class ReassessmentScreen extends ConsumerWidget {
  const ReassessmentScreen({super.key, this.recommendationId});

  final String? recommendationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recommendationId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reassessment')),
        body: EmptyState(
          title: 'Nothing to compare yet',
          message: 'Open a next step and finish its practice first.',
          actionLabel: 'See my next steps',
          onAction: () => context.pushReplacement(AppRoutes.nextSteps),
        ),
      );
    }
    final state = ref.watch(outcomeProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(outcomeProvider(id)),
          ),
        ),
        data: (outcome) => _Outcome(
          outcome: outcome,
          onDone: () async {
            // Only a step that moved the concept counts as done.
            if (outcome.change != null) {
              try {
                await ref
                    .read(recommendationsRepositoryProvider)
                    .setStatus(id, 'done');
              } catch (_) {
                // The list refreshes from the server either way.
              }
            }
            ref.invalidate(nextStepsProvider);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.outcome, required this.onDone});

  final Outcome outcome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.lg),
        if (outcome.improved)
          const Icon(Icons.celebration, size: 64, color: AppColors.warning),
        const SizedBox(height: AppSpacing.md),
        if (outcome.concept != null)
          Text(
            outcome.concept!,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Ring(label: 'Before', value: outcome.before),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Icon(Icons.arrow_forward),
            ),
            _Ring(label: 'Now', value: outcome.after),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          outcome.message,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: 'Back to my next steps', onPressed: onDone),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MasteryRing(
          value: (value ?? 0) / 100,
          size: 96,
          strokeWidth: 9,
          label: value == null ? '–' : '$value%',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
