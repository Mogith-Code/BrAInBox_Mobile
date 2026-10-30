import 'dart:math' as math;

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/insights_repository.dart';
import '../../domain/insights_models.dart';
import '../../domain/insights_summary.dart';
import 'insights_style.dart';

/// White rounded card used by every summary card.
class InsightsPanel extends StatelessWidget {
  const InsightsPanel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = InsightsColors.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: InsightsColors.line(context)),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          child,
        ],
      ),
    );
  }
}

/// "This week ⌄" pill that picks the summary period.
class InsightsPeriodSelector extends StatelessWidget {
  const InsightsPeriodSelector({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final InsightsPeriod period;
  final ValueChanged<InsightsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<InsightsPeriod>(
      tooltip: 'Change period',
      initialValue: period,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final value in InsightsPeriod.values)
          PopupMenuItem(value: value, child: Text(value.label)),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: InsightsColors.line(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period.label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Mastery ring and the Mastered / Strong / Improving / Weak legend.
///
/// Uses `mastery` from the summary. Until the backend has
/// `/insights/summary`, [fallback] (built from `/insights/topics`) is shown.
class MasteryCard extends StatelessWidget {
  const MasteryCard({super.key, required this.summary, required this.fallback});

  final AsyncValue<InsightsSummary> summary;
  final MasterySummary fallback;

  /// The legend from the topic statuses of `GET /insights/topics`:
  /// strong -> Mastered, good -> Strong, developing -> Improving,
  /// weak and very weak -> Weak. Only counts what the backend decided.
  static MasterySummary fromTopics(TopicInsights data) {
    final counts = data.statusCounts;
    int count(TopicStatus status) => counts[status] ?? 0;
    return MasterySummary(
      percent: data.overall.percent,
      bands: [
        MasteryBand(
          key: MasteryBandKey.mastered,
          label: 'Mastered',
          topicCount: count(TopicStatus.strong),
        ),
        MasteryBand(
          key: MasteryBandKey.strong,
          label: 'Strong',
          topicCount: count(TopicStatus.good),
        ),
        MasteryBand(
          key: MasteryBandKey.improving,
          label: 'Improving',
          topicCount: count(TopicStatus.developing),
        ),
        MasteryBand(
          key: MasteryBandKey.weak,
          label: 'Weak',
          topicCount: count(TopicStatus.weak) + count(TopicStatus.veryWeak),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (summary.isLoading && !summary.hasValue) {
      return const InsightsPanel(child: _CardLoading(height: 128));
    }
    final mastery = summary.value?.mastery ?? fallback;
    return InsightsPanel(
      child: Row(
        children: [
          _MasteryRing(percent: mastery.percent),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: [
                for (final band in mastery.bands) _LegendRow(band: band),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  const _MasteryRing({required this.percent});

  final double? percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Mastery ${InsightsText.percentSpoken(percent)}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 116,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: percent == null ? 0 : (percent! / 100).clamp(0.0, 1.0),
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: InsightsPalette.track(context),
              color: AppColors.primary,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percent == null ? '—' : '${percent!.round()}%',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: InsightsColors.text(context),
                    ),
                  ),
                  Text(
                    'mastery',
                    style: textTheme.bodySmall?.copyWith(
                      color: InsightsColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.band});

  final MasteryBand band;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topics = '${band.topicCount} topic${band.topicCount == 1 ? '' : 's'}';
    return Semantics(
      container: true,
      label: '${band.label}: $topics',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: InsightsPalette.forBand(band.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(band.label, style: textTheme.bodyMedium)),
            Text(
              topics,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Study time bars ("13.7h this week").
class StudyTimeCard extends StatelessWidget {
  const StudyTimeCard({
    super.key,
    required this.summary,
    required this.period,
    required this.onRetry,
  });

  final AsyncValue<InsightsSummary> summary;
  final InsightsPeriod period;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final studyTime = summary.value?.studyTime;
    final hasTime = studyTime != null && studyTime.totalMinutes > 0;
    return InsightsPanel(
      title: 'Study time',
      trailing: hasTime ? _total(context, studyTime) : null,
      child: _SummaryState(
        summary: summary,
        onRetry: onRetry,
        comingSoon: 'Your daily study time will show here.',
        empty: hasTime ? null : 'No study time recorded ${period.inlineLabel}.',
        builder: () => _StudyBars(bars: studyTime!.bars),
      ),
    );
  }

  Widget _total(BuildContext context, StudyTimeSummary studyTime) {
    final textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: InsightsText.hours(studyTime.totalMinutes),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: ' ${period.inlineLabel}',
            style: textTheme.bodyMedium?.copyWith(
              color: InsightsColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyBars extends StatelessWidget {
  const _StudyBars({required this.bars});

  final List<StudyTimeBar> bars;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: InsightsColors.mutedText(context),
    );
    // Room for the "1.5h" label above the tallest bar, at any text size.
    final valueHeight =
        MediaQuery.textScalerOf(context).scale(valueStyle?.fontSize ?? 11) *
            (valueStyle?.height ?? 1.5) +
        AppSpacing.xs;
    final most = bars.fold<int>(0, (m, b) => math.max(m, b.minutes));
    return SizedBox(
      height: 150 + valueHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Semantics(
                container: true,
                label: '${bar.label}: ${InsightsText.hours(bar.minutes)}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final maxBar = math.max(
                              4.0,
                              box.maxHeight -
                                  valueHeight -
                                  2, // 2: text rounding
                            );
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (bar.minutes > 0)
                                  Text(
                                    InsightsText.hours(bar.minutes),
                                    style: valueStyle,
                                    maxLines: 1,
                                  ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  height: most == 0
                                      ? 4
                                      : math.max(
                                          4,
                                          maxBar * bar.minutes / most,
                                        ),
                                  decoration: BoxDecoration(
                                    color: bar.highlight
                                        ? AppColors.primary
                                        : InsightsPalette.barSoft(context),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        bar.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: bar.highlight
                              ? AppColors.primary
                              : InsightsColors.mutedText(context),
                          fontWeight: bar.highlight
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Accuracy line chart ("+22% in 8 wks").
class AccuracyTrendCard extends StatelessWidget {
  const AccuracyTrendCard({
    super.key,
    required this.summary,
    required this.onRetry,
  });

  final AsyncValue<InsightsSummary> summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final trend = summary.value?.accuracyTrend;
    final points = trend?.points ?? const <AccuracyPoint>[];
    final enough = points.where((p) => p.percent != null).length >= 2;
    return InsightsPanel(
      title: 'Accuracy trend',
      trailing: enough && trend!.changePoints != null
          ? _change(context, trend)
          : null,
      child: _SummaryState(
        summary: summary,
        onRetry: onRetry,
        comingSoon: 'How your quiz accuracy changes week by week.',
        empty: enough
            ? null
            : 'Finish quizzes in two different weeks to see '
                  'a trend.',
        builder: () => _TrendChart(points: points),
      ),
    );
  }

  Widget _change(BuildContext context, AccuracyTrend trend) {
    final change = trend.changePoints!;
    final color = change > 0
        ? InsightsPalette.positive
        : change < 0
        ? InsightsPalette.negative
        : InsightsColors.mutedText(context);
    final window = trend.windowLabel.isEmpty ? '' : ' in ${trend.windowLabel}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${InsightsText.change(change)}$window',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<AccuracyPoint> points;

  @override
  Widget build(BuildContext context) {
    final last = points.lastWhere((p) => p.percent != null);
    final spoken = [
      for (final p in points)
        '${p.label}: ${InsightsText.percentSpoken(p.percent)}',
    ].join(', ');
    return Semantics(
      container: true,
      label: 'Accuracy by week. $spoken',
      excludeSemantics: true,
      child: SizedBox(
        height: 130,
        child: CustomPaint(
          painter: _TrendPainter(
            points: points,
            lastLabel: '${last.percent!.round()}%',
            line: AppColors.secondary,
            accent: AppColors.primary,
            grid: InsightsColors.line(context),
            dotFill: Theme.of(context).colorScheme.surface,
            labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.lastLabel,
    required this.line,
    required this.accent,
    required this.grid,
    required this.dotFill,
    required this.labelStyle,
  });

  final List<AccuracyPoint> points;
  final String lastLabel;
  final Color line;
  final Color accent;
  final Color grid;
  final Color dotFill;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 26.0; // room for the last value label
    const bottom = 8.0;
    const side = 8.0;
    final height = size.height - top - bottom;
    final width = size.width - side * 2;

    // Dashed grid lines.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = top + height * i / 2;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), gridPaint);
      }
    }

    final values = [for (final p in points) ?p.percent];
    final low = math.max(0.0, values.reduce(math.min) - 10);
    final high = math.min(100.0, values.reduce(math.max) + 10);
    final span = math.max(1.0, high - low);
    final step = points.length == 1 ? 0.0 : width / (points.length - 1);

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final percent = points[i].percent;
      if (percent == null) continue;
      offsets.add(
        Offset(side + step * i, top + height * (1 - (percent - low) / span)),
      );
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }

    // Area under the line.
    final area = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dots: white with a line-coloured ring; the last one filled in accent.
    for (final o in offsets.take(offsets.length - 1)) {
      canvas
        ..drawCircle(o, 5, Paint()..color = dotFill)
        ..drawCircle(
          o,
          5,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
    final end = offsets.last;
    canvas.drawCircle(end, 6, Paint()..color = accent);

    final label = TextPainter(
      text: TextSpan(text: lastLabel, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = math.min(
      size.width - label.width,
      math.max(0.0, end.dx - label.width / 2),
    );
    label.paint(canvas, Offset(labelX, end.dy - label.height - 8));
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points || old.line != line || old.grid != grid;
}

/// One bar per syllabus unit.
class UnitMasteryCard extends StatelessWidget {
  const UnitMasteryCard({
    super.key,
    required this.summary,
    required this.onRetry,
  });

  final AsyncValue<InsightsSummary> summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final units = summary.value?.units ?? const <UnitMastery>[];
    return InsightsPanel(
      title: 'Unit mastery',
      child: _SummaryState(
        summary: summary,
        onRetry: onRetry,
        comingSoon: 'Your mastery of each syllabus unit will show here.',
        empty: units.isEmpty ? 'No units attempted yet.' : null,
        builder: () =>
            Column(children: [for (final unit in units) _UnitRow(unit: unit)]),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit});

  final UnitMastery unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = unit.unitNumber == null
        ? unit.name
        : '${unit.unitNumber}. ${unit.name}';
    final percent = unit.percent;
    return Semantics(
      container: true,
      label: '$name, ${InsightsText.percentSpoken(percent)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                name,
                style: textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: percent == null ? 0 : (percent / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: InsightsPalette.track(context),
                  color: InsightsPalette.forStatus(unit.status),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                percent == null ? '—' : '${percent.round()}%',
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading / coming soon / error / empty handling inside a summary card.
class _SummaryState extends StatelessWidget {
  const _SummaryState({
    required this.summary,
    required this.onRetry,
    required this.comingSoon,
    required this.empty,
    required this.builder,
  });

  final AsyncValue<InsightsSummary> summary;
  final VoidCallback onRetry;

  /// Shown under "Coming soon" while the backend has no endpoint.
  final String comingSoon;

  /// Shown instead of the content when not null.
  final String? empty;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasValue) {
      if (summary.error is InsightsNotAvailableYet) {
        return _CardMessage(
          icon: Icons.schedule_rounded,
          title: 'Coming soon',
          message: comingSoon,
        );
      }
      if (summary.hasError) {
        return _CardMessage(
          icon: Icons.error_outline_rounded,
          title: "Couldn't load this",
          message: '${summary.error}',
          onRetry: onRetry,
        );
      }
      return const _CardLoading(height: 120);
    }
    if (empty != null) {
      return _CardMessage(icon: Icons.info_outline_rounded, message: empty!);
    }
    return builder();
  }
}

class _CardMessage extends StatelessWidget {
  const _CardMessage({
    required this.icon,
    required this.message,
    this.title,
    this.onRetry,
  });

  final IconData icon;
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = InsightsColors.mutedText(context);
    return Row(
      children: [
        Icon(icon, color: muted),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!, style: textTheme.titleSmall),
              Text(message, style: textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _CardLoading extends StatelessWidget {
  const _CardLoading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: InsightsColors.line(context).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
