import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/admin_page.dart';
import '../../application/mcq_mapping_controller.dart';
import '../../domain/mcq_mapping_models.dart';

/// "Suggest with AI": the AI's misconception per wrong option. Nothing is
/// saved until the admin presses Accept on that option.
class SuggestionsPanel extends ConsumerWidget {
  const SuggestionsPanel({
    super.key,
    required this.questionId,
    required this.onSuggest,
    required this.onAccept,
  });

  /// Null for a question that isn't saved yet.
  final String? questionId;
  final VoidCallback onSuggest;
  final ValueChanged<MisconceptionSuggestion> onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = questionId;
    final state = id == null
        ? const SuggestionsState()
        : ref.watch(suggestionsProvider(id));
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return AdminPanel(
      title: 'AI misconception suggestions',
      trailing: OutlinedButton.icon(
        onPressed: id == null || state.running ? null : onSuggest,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: Text(state.items == null ? 'Suggest with AI' : 'Ask again'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.running)
            const AiGeneratingLoader(
              message: 'Finding the misconception behind each wrong option...',
            )
          else if (state.error != null)
            ErrorBanner(message: state.error!, onRetry: onSuggest)
          else if (state.items == null)
            Text(
              'The AI proposes a misconception for each wrong option. '
              'Check each one and accept the ones you agree with.',
              style: muted,
            )
          else if (state.items!.isEmpty)
            Text('The AI had no suggestions for this question.', style: muted)
          else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: AiBadge(label: 'AI suggestions · check each one'),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final s in state.items!)
              _SuggestionTile(
                suggestion: s,
                decision: state.decisionOf(s),
                saving: state.saving.contains(s.optionId),
                onAccept: () => onAccept(s),
                onDismiss: () =>
                    ref.read(suggestionsProvider(id!).notifier).dismiss(s),
              ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.decision,
    required this.saving,
    required this.onAccept,
    required this.onDismiss,
  });

  final MisconceptionSuggestion suggestion;
  final SuggestionDecision decision;
  final bool saving;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final match = s.isNew
        ? const StatusBadge(label: 'New misconception', tone: BadgeTone.info)
        : StatusBadge(
            label: s.similarity == null
                ? 'Already in the bank'
                : 'Already in the bank · '
                      '${Formatters.percent(s.similarity!)} match',
            tone: BadgeTone.neutral,
            showIcon: false,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Option ${s.label} · ${s.optionText}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Now: ${(s.current ?? '').trim().isEmpty ? 'none' : s.current}',
            style: muted,
          ),
          Text.rich(
            TextSpan(
              text: 'Suggested: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: s.suggested,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              match,
              ...switch (decision) {
                SuggestionDecision.accepted => const [
                  StatusBadge(
                    label: 'Accepted · saved',
                    tone: BadgeTone.success,
                  ),
                ],
                SuggestionDecision.dismissed => const [
                  StatusBadge(label: 'Dismissed', tone: BadgeTone.neutral),
                ],
                SuggestionDecision.open when s.isUnchanged => const [
                  StatusBadge(label: 'Same as now', tone: BadgeTone.success),
                ],
                SuggestionDecision.open => [
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: saving ? null : onAccept,
                      child: Text('Accept for ${s.label}'),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: saving ? null : onDismiss,
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              },
            ],
          ),
        ],
      ),
    );
  }
}
