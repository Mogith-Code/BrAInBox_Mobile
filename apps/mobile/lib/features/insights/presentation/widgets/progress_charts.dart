import 'package:brainbox_core/brainbox_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/progress_providers.dart';
import '../../domain/progress_models.dart';
import 'insights_style.dart';
import 'mastery_card.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "1 h 25 min", "40 min", "0 min".
String studyDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "Study time" and "Accuracy trend" cards (`GET /insights/overview`).
///
/// Load on their own, so a slow or failed request never hides the rest of
/// the overview.
class ProgressCharts extends ConsumerWidget {
  const ProgressCharts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsOverviewProvider);
    final data = state.value;
    Widget body(Widget Function(InsightsOverview) loaded, String what) =>
        switch (data) {
          null when state.hasError => _ChartError(
            message: '${state.error}',
            onRetry: () => ref.invalidate(insightsOverviewProvider),
          ),
          null => _ChartLoading(label: 'Loading $what'),
          _ => loaded(data),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsightsPanel(
          title: 'Study time',
          child: body((d) => StudyTimeChart(overview: d), 'study time'),
        ),
        // One error / loading message is enough for the same request.
        if (data != null)
          InsightsPanel(
            title: 'Accuracy trend',
            child: AccuracyTrendChart(overview: data),
          ),
      ],
    );
  }
}

/// This week's minutes per day as bars.
class StudyTimeChart extends StatelessWidget {
  const StudyTimeChart({super.key, required this.overview});

  final InsightsOverview overview;

  static const double height = 150;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = InsightsColors.mutedText(context);
    final days = overview.studyTime;
    final total = overview.studyMinutesWeek;
    final summary = Text.rich(
      TextSpan(
        text: studyDuration(total),
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: InsightsColors.text(context),
        ),
        children: [
          TextSpan(
            text: '  in the last 7 days',
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
    if (days.isEmpty || total == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summary,
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No study time this week yet. Time spent on quizzes and lessons '
            'shows up here.',
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      );
    }

    final maxMinutes = days
        .map((d) => d.minutes)
        .reduce((a, b) => a > b ? a : b);
    final spoken = [
      for (final d in days)
        '${_weekdays[d.date.weekday - 1]} ${studyDuration(d.minutes)}',
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: 'Study time per day: $spoken',
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                maxY: (maxMinutes * 1.15).ceilToDouble(),
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: InsightsColors.line(context),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _weekdays[days[i].date.weekday - 1],
                            style: textTheme.labelSmall?.copyWith(color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${_weekdays[days[group.x].date.weekday - 1]}\n'
                      '${studyDuration(rod.toY.round())}',
                      textTheme.labelMedium!.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].minutes.toDouble(),
                          width: 16,
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// MCQ accuracy per day (last 14 days, only days with answers) as a line.
class AccuracyTrendChart extends StatelessWidget {
  const AccuracyTrendChart({super.key, required this.overview});

  final InsightsOverview overview;

  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = InsightsColors.mutedText(context);
    final points = overview.accuracyPoints;
    if (points.isEmpty) {
      return Text(
        'Answer a few questions to see how your accuracy changes over the '
        'last 14 days.',
        style: textTheme.bodyMedium?.copyWith(color: muted),
      );
    }

    final latest = points.last;
    final spoken = [
      for (final p in points) '${_shortDate(p.date)} ${p.accuracy} percent',
    ].join(', ');
    final lineColor = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '${latest.accuracy}%',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: InsightsColors.text(context),
            ),
            children: [
              TextSpan(
                text:
                    '  on ${_shortDate(latest.date)} '
                    '(${latest.answered} answered)',
                style: textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: 'Accuracy per day: $spoken',
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: points.length == 1 ? 1 : (points.length - 1).toDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: InsightsColors.line(context),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 50,
                      // No "0%" tick: the app never shows 0% for missing data.
                      getTitlesWidget: (value, meta) => value <= 0
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '${value.toInt()}%',
                                style: textTheme.labelSmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        // Label only the first and last day.
                        final show =
                            value == i &&
                            i >= 0 &&
                            i < points.length &&
                            (i == 0 || i == points.length - 1);
                        if (!show) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _shortDate(points[i].date),
                            style: textTheme.labelSmall?.copyWith(color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${_shortDate(points[s.x.toInt()].date)}\n'
                          '${s.y.round()}% · '
                          '${points[s.x.toInt()].answered} answered',
                          textTheme.labelMedium!.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].accuracy!.toDouble()),
                    ],
                    color: lineColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        height: StudyTimeChart.height,
        decoration: BoxDecoration(
          color: InsightsColors.line(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = InsightsColors.mutedText(context);
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, color: muted),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
