import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/home_controller.dart';
import '../domain/home_models.dart';
import 'widgets/home_cards.dart';

/// Home dashboard (Figma B1).
///
/// Route: `/home` (first tab). Pull to refresh; skeleton while loading;
/// error banner with Retry. The avatar opens Settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.clock});

  /// For tests: the time used for the greeting and date.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final now = (clock ?? DateTime.now)();

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
      // DEBUG ONLY: jump to any screen while features are being built.
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              tooltip: 'Dev menu',
              onPressed: () => context.push(AppRoutes.devMenu),
              child: const Icon(Icons.developer_mode),
            )
          : null,
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
      if (a.type == 'diagnostic') {
        context.push(AppRoutes.diagnostic);
        return;
      }
      // TODO(samni): open the real revision / practice screen per type.
      final topicId = a.target?.topicId;
      if (topicId == null) {
        context.go(AppRoutes.learn);
      } else {
        context.push(AppRoutes.topicPath(topicId));
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
            onAvatarTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (action != null) ...[
            NextBestActionCard(
              action: action,
              onStart: () => openAction(action),
            ),
            const SizedBox(height: AppSpacing.md),
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
                    // TODO(keshomigha): the topic page is still a placeholder.
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
