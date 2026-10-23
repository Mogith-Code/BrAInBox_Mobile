import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/dashboard_models.dart';

/// One KPI tile: icon, sparkline, label, big number and change text.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.kpi});

  final DashboardKpi kpi;

  /// The accent colour and icon of each kind of KPI.
  static (Color, IconData) styleOf(DashboardKpiKind kind) => switch (kind) {
    DashboardKpiKind.students => (AppColors.primary, Icons.people_outline),
    DashboardKpiKind.quizzes => (
      AppColors.secondary,
      Icons.check_circle_outline,
    ),
    DashboardKpiKind.aiReview => (AppColors.warning, Icons.auto_awesome),
    DashboardKpiKind.reports => (AppColors.error, Icons.flag_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (color, icon) = styleOf(kpi.kind);
    final (trendIcon, trendColor) = switch (kpi.trend) {
      DashboardTrend.good => (Icons.trending_up, AppColors.secondary),
      DashboardTrend.bad => (Icons.trending_down, AppColors.error),
      DashboardTrend.warning => (
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
    };
    final value = Formatters.thousands(kpi.value);

    return Card(
      child: Semantics(
        container: true,
        label: '${kpi.label}: $value. ${kpi.delta}',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const Spacer(),
                    if (kpi.sparkline.length > 1)
                      SizedBox(
                        width: 96,
                        height: 32,
                        child: CustomPaint(
                          painter: _SparklinePainter(kpi.sparkline, color),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  kpi.label,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (kpi.delta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(trendIcon, size: 16, color: trendColor),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          kpi.delta,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small line through [values], scaled to fill the box.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    // Keep the 2 px stroke inside the box.
    const inset = 2.0;
    final height = size.height - inset * 2;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = inset + height - (values[i] - min) / range * height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
