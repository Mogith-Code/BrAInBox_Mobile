import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/insights_controller.dart';
import '../../data/insights_repository.dart';
import '../../domain/insights_models.dart';
import '../insights_navigation.dart';
import 'insights_style.dart';

/// Loading, empty, error and pull-to-refresh handling shared by every
/// Insights screen. [builder] returns the list items for the loaded data.
class InsightsAsyncBody extends ConsumerWidget {
  const InsightsAsyncBody({
    super.key,
    required this.attemptId,
    required this.builder,
    this.onRefresh,
  });

  final String? attemptId;
  final List<Widget> Function(BuildContext context, TopicInsights data) builder;

  /// Also reloads other data on the screen (pull-to-refresh, Retry).
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = insightsControllerProvider(attemptId: attemptId);
    final state = ref.watch(provider);
    Future<void> refresh() => Future.wait([
      ref.read(provider.notifier).refresh(),
      ?onRefresh?.call(),
    ]);

    // Backend has no profile for this account: send them to set one up.
    ref.listen(provider, (_, next) {
      if (next.error is InsightsNotRegistered) {
        InsightsNav.goToProfileSetup(context);
      }
    });

    final data = state.value;
    if (data == null) {
      if (state.hasError) {
        return InsightsErrorView(error: state.error!, onRetry: refresh);
      }
      return const InsightsSkeleton();
    }

    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            EmptyState(
              icon: Icons.insights_rounded,
              title: 'No results yet',
              message: 'Finish a quiz to see your topic scores.',
              actionLabel: 'Go to Practice',
              onAction: () => InsightsNav.goToPractice(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          // A failed refresh keeps the old data on screen, with this banner.
          if (state.hasError)
            ErrorBanner(message: '${state.error}', onRetry: refresh),
          ...builder(context, data),
        ],
      ),
    );
  }
}

/// Full-screen error, chosen by the kind of [InsightsFailure].
class InsightsErrorView extends StatelessWidget {
  const InsightsErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (error) {
      InsightsUnavailable() => EmptyState(
        icon: Icons.lock_outline_rounded,
        title: "This result isn't available",
        message: 'It may belong to another account or no longer exist.',
        actionLabel: 'Back',
        onAction: () => InsightsNav.back(context),
      ),
      InsightsNotRegistered() => EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Finish your profile',
        message: 'Set up your profile to see your results.',
        actionLabel: 'Set up profile',
        onAction: () => InsightsNav.goToProfileSetup(context),
      ),
      InsightsOffline(:final message) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: "You're offline",
        message: message,
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
      _ => Center(
        child: ErrorBanner(message: '$error', onRetry: onRetry),
      ),
    };
  }
}

/// Grey placeholder cards shown while the first load is running.
class InsightsSkeleton extends StatefulWidget {
  const InsightsSkeleton({super.key});

  @override
  State<InsightsSkeleton> createState() => _InsightsSkeletonState();
}

class _InsightsSkeletonState extends State<InsightsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = InsightsColors.line(context);
    Widget box(double height) => Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
    return Semantics(
      label: 'Loading your results',
      child: FadeTransition(
        opacity: _pulse,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          children: [box(148), box(48), box(96), box(72), box(72)],
        ),
      ),
    );
  }
}

/// Section title used on every Insights screen.
class InsightsSectionTitle extends StatelessWidget {
  const InsightsSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
