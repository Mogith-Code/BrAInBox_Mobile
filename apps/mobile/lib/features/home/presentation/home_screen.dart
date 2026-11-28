import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../profile/application/profile_overview_controller.dart';
import '../../profile/presentation/widgets/achievement_dialog.dart';
import '../../visuals/presentation/widgets/visualise_anything_card.dart';
import '../application/home_controller.dart';
import '../domain/home_models.dart';
import 'widgets/home_cards.dart';

/// Home dashboard (Figma B1).
///
/// Route: `/home` (first tab). Pull to refresh; skeleton while loading;
/// error banner with Retry. The avatar opens the Profile; a newly
/// unlocked achievement pops up once (Figma F8).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.clock});

  /// For tests: the time used for the greeting and date.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final now = (clock ?? DateTime.now)();

    // Figma F8: show a newly unlocked badge once, then mark it seen.
    ref.listen(profileOverviewControllerProvider, (previous, next) {
      final badge = next.value?.unseen;
      if (badge == null || previous?.value?.unseen?.id == badge.id) return;
      ref.read(profileOverviewControllerProvider.notifier).markSeen(badge.id);
      showAchievementUnlocked(context, badge);
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (state) {
          AsyncData(:final value) => _Dashboard(summary: value, now: now),
          AsyncError(:final error) when !state.hasValue => Center(
            child: ErrorBanner(
              message: ErrorMessages.of(error),
              onRetry: () => ref.invalidate(homeControllerProvider),
            ),
          ),
          _ when state.hasValue => _Dashboard(
            summary: state.requireValue,
            now: now,
          ),
          _ => const HomeSkeleton(),
        },
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.summary, required this.now});

  final HomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(homeControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final action = summary.nextBestAction;

    void openAction(NextBestAction a) {
      final topicId = a.target?.topicId;
      switch (a.type) {
        case 'diagnostic':
          context.push(AppRoutes.diagnostic);
        // "Start 10-min revision": the topic page (notes, videos, practice).
        case 'revise' || 'revision' when topicId != null:
          context.push(AppRoutes.topicPath(topicId));
        case 'practice' when topicId != null:
          context.push(
            AppRoutes.quizSetupPath(topicId: topicId, mode: 'quick'),
          );
        // Unknown type or no topic: the full list of recommendations.
        default:
          context.push(AppRoutes.nextSteps);
      }
    }

    Future<void> toggle(PlanItem item) async {
      final ok = await controller.togglePlanItem(item.id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't update your plan. Please try again."),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          HomeHeader(
            summary: summary,
            now: now,
            // `go`, not `push`: Profile lives in the Settings tab, and pushing
            // it could put the tab shell on the stack twice.
            onAvatarTap: () => context.go(AppRoutes.settingsProfile),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (action != null) ...[
            NextBestActionCard(
              action: action,
              onStart: () => openAction(action),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.nextSteps),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('See all next steps'),
              ),
            ),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Figma: the plan takes about two thirds of the row.
                Expanded(
                  flex: 2,
                  child: TodaysPlanCard(
                    plan: summary.todaysPlan,
                    onToggle: (item) => unawaited(toggle(item)),
                    onOpen: (_) => context.push(AppRoutes.studyPlan),
                    onSeePlan: () => context.push(AppRoutes.studyPlan),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: MasteryCard(
                    mastery: asFraction(summary.overallMastery),
                    changeWeek: summary.masteryChangeWeek,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // AI visuals for any idea, not only the topic being studied.
          const VisualiseAnythingCard(),
          if (summary.continueLearning.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Continue learning',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.learn),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summary.continueLearning.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) {
                  final item = summary.continueLearning[i];
                  return ContinueCard(
                    item: item,
                    tint: i.isEven
                        ? AppColors.primarySoft
                        : AppColors.successSoft,
                    onTap: () =>
                        context.push(AppRoutes.topicPath(item.topicId)),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
