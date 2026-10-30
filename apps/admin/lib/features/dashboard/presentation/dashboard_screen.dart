import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_models.dart';
import 'widgets/activity_chart_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/kpi_card.dart';
import 'widgets/missed_topics_card.dart';
import 'widgets/recent_reports_card.dart';

/// Dashboard screen - KPI tiles (students, questions, pending reviews) and activity.
///
/// Route: `/dashboard`
///
/// Keep this file UI-only: read state from the controller and call its
/// methods. Never call Dio / Firebase here.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ),
      data: (summary) => _DashboardBody(summary: summary),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary});

  final DashboardSummary summary;

  static const double _gap = AppSpacing.lg;

  /// From this width the chart and the reports sit side by side.
  static const double _twoColumnWidth = 1000;

  void _notConnected(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is not connected yet.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final firstName = (user == null || user.firstName.isEmpty)
        ? null
        : user.firstName;

    final header = DashboardHeader(
      now: DateTime.now(),
      firstName: firstName,
      batchLabel: summary.batchLabel,
      // TODO(samni): connect search, notifications and export when the
      // backend supports them.
      onSearch: (_) => _notConnected(context, 'Search'),
      onNotifications: () => _notConnected(context, 'Notifications'),
      onExport: () => _notConnected(context, 'Export'),
    );
    final chart = ActivityChartCard(activity: summary.activity);
    final reports = RecentReportsCard(
      reports: summary.recentReports,
      onOpenQueue: () => context.go(AdminRoutes.moderation),
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (summary.message.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _DataNotice(message: summary.message),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (summary.kpis.isNotEmpty) ...[
                  _KpiGrid(kpis: summary.kpis, width: width, gap: _gap),
                  const SizedBox(height: _gap),
                ],
                if (width >= _twoColumnWidth)
                  // Same height for both cards.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: chart),
                        const SizedBox(width: _gap),
                        Expanded(child: reports),
                      ],
                    ),
                  )
                else ...[
                  chart,
                  const SizedBox(height: _gap),
                  reports,
                ],
                const SizedBox(height: _gap),
                MissedTopicsCard(
                  topics: summary.missedTopics,
                  attempts: summary.missedTopicsAttempts,
                  // TODO(samni): open "create practice set" when it exists.
                  onCreateSet: (_) =>
                      _notConnected(context, 'Creating practice sets'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 4 tiles in a row on wide screens, 2 on medium, 1 on narrow.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis, required this.width, required this.gap});

  final List<DashboardKpi> kpis;
  final double width;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final columns = width >= 1000
        ? 4
        : width >= 520
        ? 2
        : 1;
    final tileWidth = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final kpi in kpis)
          SizedBox(
            width: tileWidth,
            child: KpiCard(kpi: kpi),
          ),
      ],
    );
  }
}

/// A small amber note, e.g. "Placeholder data - API not connected yet.", so
/// nobody mistakes sample figures for live ones.
class _DataNotice extends StatelessWidget {
  const _DataNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.ink),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
