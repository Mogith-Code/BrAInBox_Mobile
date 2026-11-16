import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/unit_detail_controller.dart';
import '../domain/syllabus_models.dart';
import 'widgets/topic_row.dart';
import 'widgets/unit_card.dart';

/// Unit detail: the topics in one unit.
///
/// Route: `/learn/unit/:unitId` (inside the Learn tab). Teal → indigo
/// gradient header with the unit's mastery ring, the weak-topic banner,
/// then one row per topic.
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unitDetailControllerProvider(unitId));

    return Scaffold(
      backgroundColor: context.learnBackground,
      body: switch (state) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: ref
              .read(unitDetailControllerProvider(unitId).notifier)
              .refresh,
          child: _UnitDetailBody(detail: value),
        ),
        AsyncError(:final error) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LearnBackButton(onDark: false),
              ),
              Expanded(
                child: ErrorCard(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(unitDetailControllerProvider(unitId)),
                ),
              ),
            ],
          ),
        ),
        _ => const _UnitDetailSkeleton(),
      },
    );
  }
}

class _UnitDetailBody extends StatelessWidget {
  const _UnitDetailBody({required this.detail});

  final UnitDetail detail;

  @override
  Widget build(BuildContext context) {
    final topics = detail.topics;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _UnitHeader(detail: detail)),
        if (detail.weakCount > 0)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _WeakTopicsBanner()),
          ),
        if (topics.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: LearnEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No topics yet',
              message: 'Topics for this unit will show up here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.separated(
              itemCount: topics.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm + 2),
              itemBuilder: (context, i) => TopicRow(
                topic: topics[i],
                onTap: () => context.push(
                  AppRoutes.unitTopicPath(detail.unit.id, topics[i].id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Gradient header: back, "UNIT 6", name, counts, yellow ring.
class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.detail});

  final UnitDetail detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unit = detail.unit;
    final topics = '${unit.topicCount} topic${unit.topicCount == 1 ? '' : 's'}';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LearnBackButton(onDark: true),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT ${unit.order}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.taglineOnDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      header: true,
                      child: Text(
                        unit.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$topics · ${detail.masteredCount} mastered · '
                      '${detail.weakCount} weak',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.taglineOnDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              ProgressRing(
                value: unit.mastery,
                size: 64,
                strokeWidth: 6,
                color: AppColors.amber,
                trackColor: AppColors.white.withValues(alpha: 0.25),
                labelColor: AppColors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Back button used on Learn screens. Goes to `/learn` when there is
/// nothing to pop (e.g. a deep link).
class LearnBackButton extends StatelessWidget {
  const LearnBackButton({super.key, required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SoftIconButton(
      tooltip: 'Back',
      icon: Icons.arrow_back,
      background: onDark
          ? AppColors.white.withValues(alpha: 0.18)
          : AppColors.primarySoft,
      foreground: onDark ? AppColors.white : AppColors.primary,
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.learn),
    );
  }
}

/// "Orange dot = weak topic, flagged from your answers".
class _WeakTopicsBanner extends StatelessWidget {
  const _WeakTopicsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              'Orange dot = weak topic, flagged from your answers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warningDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient block + grey rows while the unit loads.
class _UnitDetailSkeleton extends StatelessWidget {
  const _UnitDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180 + MediaQuery.paddingOf(context).top,
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          alignment: Alignment.topLeft,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.paddingOf(context).top + AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: const LearnBackButton(onDark: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Expanded(child: SkeletonList(label: 'Loading unit', height: 68)),
      ],
    );
  }
}
