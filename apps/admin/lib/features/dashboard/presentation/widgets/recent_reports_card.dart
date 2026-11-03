import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/dashboard_models.dart';
import 'dashboard_card.dart';

/// "Recent reports": the latest reported content, with a link to the
/// moderation queue.
class RecentReportsCard extends StatelessWidget {
  const RecentReportsCard({
    super.key,
    required this.reports,
    required this.onOpenQueue,
  });

  final List<DashboardReport> reports;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Recent reports',
      trailing: TextButton(
        onPressed: onOpenQueue,
        child: const Text('Open queue →'),
      ),
      child: reports.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No reports right now.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < reports.length; i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _ReportRow(report: reports[i]),
                ],
              ],
            ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final DashboardReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (color, severity) = switch (report.severity) {
      ReportSeverity.high => (AppColors.error, 'High priority'),
      ReportSeverity.medium => (AppColors.warning, 'Medium priority'),
    };

    return MergeSemantics(
      child: Row(
        children: [
          Semantics(
            label: severity,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.flag_outlined, size: 18, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (report.subtitle.isNotEmpty)
                  Text(
                    report.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            report.meta,
            style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
