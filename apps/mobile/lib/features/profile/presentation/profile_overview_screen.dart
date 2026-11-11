import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/profile_overview_controller.dart';
import '../domain/profile_overview_models.dart';
import 'widgets/achievement_dialog.dart';

/// Profile (Figma F1): who the student is, streak / questions / topics
/// mastered, achievements and their goal. Edit profile opens the setup
/// steps; the gear opens Settings.
///
/// Route: `/profile` (opened from the avatar on Home).
class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileOverviewControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(profileOverviewControllerProvider.future),
          child: _Body(profile: value),
        ),
        AsyncError(:final error) => SafeArea(
          child: Center(
            child: ErrorBanner(
              message: ErrorMessages.of(error),
              onRetry: () => ref.invalidate(profileOverviewControllerProvider),
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile});

  final ProfileOverview profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      if (p.streamLabel.isNotEmpty) p.streamLabel,
      if (p.examYear != null) 'A/L ${p.examYear}',
    ].join(' · ');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            MediaQuery.paddingOf(context).top + AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xxl * 1.5,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    color: AppColors.white,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    color: AppColors.white,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.amber,
                child: Text(
                  Formatters.initials(p.fullName),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                p.fullName,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.taglineOnDark,
                  ),
                ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -AppSpacing.xxl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        _Stat(value: '${p.streakDays}', label: 'day streak'),
                        _Stat(
                          value: Formatters.thousands(p.questionsAnswered),
                          label: 'questions',
                        ),
                        _Stat(
                          value: '${p.topicsMastered}',
                          label: 'topics mastered',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Edit profile',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.push(AppRoutes.profileSetup),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Achievements',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${p.unlockedCount} of ${p.achievementsTotal}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.95,
                  children: [
                    for (final a in p.achievements) _Badge(achievement: a),
                  ],
                ),
                if (p.targetGrade != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _GoalCard(grade: p.targetGrade!, daysToExam: p.daysToExam),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Semantics(
      button: a.unlocked,
      label: '${a.title}${a.unlocked ? '' : ', locked'}',
      child: Card(
        color: a.unlocked ? AppColors.white : AppColors.surfaceMuted,
        child: InkWell(
          onTap: a.unlocked ? () => showAchievementUnlocked(context, a) : null,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    a.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: a.unlocked ? AppColors.ink : AppColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.grade, required this.daysToExam});

  final String grade;
  final int? daysToExam;

  @override
  Widget build(BuildContext context) {
    final days = daysToExam;
    // About one study year before the exam: the bar fills as it gets closer.
    final progress = days == null ? null : (1 - days / 365).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    grade,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target grade $grade'
                        '${days == null ? '' : ' · $days days to go'}',
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
