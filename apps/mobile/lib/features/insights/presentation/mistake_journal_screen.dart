import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/mistakes_controller.dart';
import '../domain/mistake_models.dart';

/// Mistake journal: every wrong MCQ answer with what the student picked,
/// the right answer and the misconception behind it. "Mark fixed" moves it
/// to the Fixed tab. No mistakes = the friendly empty state (Figma F5).
///
/// Route: `/insights/mistakes`. Data: `GET /mistakes`, `PATCH /mistakes/{id}`.
class MistakeJournalScreen extends ConsumerStatefulWidget {
  const MistakeJournalScreen({super.key});

  @override
  ConsumerState<MistakeJournalScreen> createState() =>
      _MistakeJournalScreenState();
}

class _MistakeJournalScreenState extends ConsumerState<MistakeJournalScreen> {
  MistakeTab _tab = MistakeTab.open;

  @override
  Widget build(BuildContext context) {
    final provider = mistakesControllerProvider(_tab);
    final state = ref.watch(provider);

    Future<void> toggle(MistakeEntry m) async {
      final ok = await ref
          .read(provider.notifier)
          .setResolved(m.id, resolved: !m.isResolved);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              !ok
                  ? "Couldn't save that. Try again."
                  : m.isResolved
                  ? 'Moved back to To fix.'
                  : 'Nice! Marked as fixed.',
            ),
          ),
        );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Mistake journal'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.insights),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SegmentedButton<MistakeTab>(
              segments: [
                for (final t in MistakeTab.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: switch (state) {
              AsyncData(:final value) when value.isEmpty =>
                _tab == MistakeTab.open
                    ? const _NoMistakes()
                    : const EmptyState(
                        icon: Icons.task_alt,
                        title: 'Nothing marked fixed yet',
                        message:
                            'Mark a mistake as fixed once you understand it.',
                      ),
              AsyncData(:final value) => RefreshIndicator(
                onRefresh: () => ref.refresh(provider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => _MistakeCard(
                    mistake: value[i],
                    onToggle: () => toggle(value[i]),
                  ),
                ),
              ),
              AsyncError(:final error) => Center(
                child: ErrorBanner(
                  message: ErrorMessages.of(error),
                  onRetry: () => ref.invalidate(provider),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Figma F5: "No mistakes yet — nice!"
class _NoMistakes extends StatelessWidget {
  const _NoMistakes();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_outlined,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No mistakes yet — nice!',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Every mistake you make in a quiz lands here so we can fix it '
              'together. Mistakes are just seeds for growth.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Take a quick quiz',
              onPressed: () => context.push(AppRoutes.quizSetup),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.mistake, required this.onToggle});

  final MistakeEntry mistake;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final m = mistake;
    final textTheme = Theme.of(context).textTheme;
    final where = [
      if (m.unitNumber != null) 'Unit ${m.unitNumber}',
      if (m.topic != null) '${m.topicNumber ?? ''} ${m.topic}'.trim(),
      if (m.createdAt != null) Formatters.relativeTime(m.createdAt!),
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (where.isNotEmpty)
              Text(
                where,
                style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              m.question ?? 'This question was removed.',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (m.yourAnswer != null)
              _Answer(
                icon: Icons.close,
                color: AppColors.error,
                label: 'You picked',
                text: m.yourAnswer!,
              ),
            if (m.correctAnswer != null)
              _Answer(
                icon: Icons.check,
                color: AppColors.successDark,
                label: 'Answer',
                text: m.correctAnswer!,
              ),
            if (m.misconception != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Likely misconception: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text:
                            m.misconception!.title +
                            (m.correction == null ? '' : '\n${m.correction}'),
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  m.isResolved ? Icons.undo : Icons.task_alt,
                  size: 18,
                ),
                label: Text(m.isResolved ? 'Not fixed yet' : 'Mark fixed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
