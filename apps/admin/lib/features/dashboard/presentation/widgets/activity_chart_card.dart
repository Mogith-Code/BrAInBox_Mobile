import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/dashboard_models.dart';
import 'dashboard_card.dart';

/// "Activity - last 14 days": quizzes (solid line + area) and notes
/// generated (dashed line).
///
/// Hover or tap the chart to see one day's numbers. Until then the busiest
/// day is highlighted.
class ActivityChartCard extends StatefulWidget {
  const ActivityChartCard({super.key, required this.activity});

  final DashboardActivity activity;

  static const Color quizzesColor = AppColors.primary;
  static const Color notesColor = AppColors.secondary;

  @override
  State<ActivityChartCard> createState() => _ActivityChartCardState();
}

class _ActivityChartCardState extends State<ActivityChartCard> {
  /// The day under the pointer, or null to highlight the busiest day.
  int? _hovered;

  DashboardActivity get _data => widget.activity;

  bool get _hasData =>
      _data.quizzes.length > 1 &&
      _data.quizzes.length == _data.notesGenerated.length &&
      _data.quizzes.length == _data.dayLabels.length;

  int get _busiestDay {
    var best = 0;
    for (var i = 1; i < _data.quizzes.length; i++) {
      if (_data.quizzes[i] > _data.quizzes[best]) best = i;
    }
    return best;
  }

  void _pointAt(Offset position, double width) {
    final index = _ActivityPainter.indexAt(
      position.dx,
      width,
      _data.quizzes.length,
    );
    if (index != _hovered) setState(() => _hovered = index);
  }

  /// What a screen reader says instead of drawing the chart.
  String get _summary {
    final q = _data.quizzes;
    final n = _data.notesGenerated;
    return 'Line chart of the last ${q.length} days. '
        'Quizzes went from ${Formatters.thousands(q.first)} on '
        '${_data.dayLabels.first} to ${Formatters.thousands(q.last)} on '
        '${_data.dayLabels.last}, highest ${Formatters.thousands(q[_busiestDay])} '
        'on ${_data.dayLabels[_busiestDay]}. Notes generated went from '
        '${Formatters.thousands(n.first)} to ${Formatters.thousands(n.last)}.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardCard(
      title: 'Activity · last 14 days',
      trailing: const Wrap(
        spacing: AppSpacing.lg,
        children: [
          _LegendItem(label: 'Quizzes', color: ActivityChartCard.quizzesColor),
          _LegendItem(
            label: 'Notes generated',
            color: ActivityChartCard.notesColor,
            dashed: true,
          ),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: !_hasData
            ? Center(
                child: Text(
                  'No activity yet.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              )
            : Semantics(
                label: _summary,
                child: ExcludeSemantics(
                  // Builder (not LayoutBuilder): the card sits inside an
                  // IntrinsicHeight, which LayoutBuilder does not support.
                  // The width is read from the laid-out size instead.
                  child: Builder(
                    builder: (context) {
                      double width() => context.size?.width ?? 0;
                      return MouseRegion(
                        onHover: (event) =>
                            _pointAt(event.localPosition, width()),
                        onExit: (_) => setState(() => _hovered = null),
                        child: GestureDetector(
                          onTapDown: (details) =>
                              _pointAt(details.localPosition, width()),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _ActivityPainter(
                              activity: _data,
                              highlighted: _hovered ?? _busiestDay,
                              axisStyle:
                                  textTheme.labelSmall?.copyWith(
                                    color: AppColors.muted,
                                  ) ??
                                  const TextStyle(fontSize: 11),
                              tooltipStyle:
                                  textTheme.labelSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  const TextStyle(fontSize: 11),
                              gridColor: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    this.dashed = false,
  });

  final String label;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 2,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4, height: 2, color: color),
                  ],
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ActivityPainter extends CustomPainter {
  _ActivityPainter({
    required this.activity,
    required this.highlighted,
    required this.axisStyle,
    required this.tooltipStyle,
    required this.gridColor,
  });

  final DashboardActivity activity;
  final int highlighted;
  final TextStyle axisStyle;
  final TextStyle tooltipStyle;
  final Color gridColor;

  // Room for the y labels (left), x labels (bottom) and the tooltip (top).
  static const double _left = 44;
  static const double _bottom = 24;
  static const double _top = 32;

  /// The day nearest to [dx] (a position across the chart).
  static int indexAt(double dx, double width, int count) {
    final plotWidth = width - _left;
    final ratio = ((dx - _left) / plotWidth).clamp(0.0, 1.0);
    return (ratio * (count - 1)).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final quizzes = activity.quizzes;
    final notes = activity.notesGenerated;
    final count = quizzes.length;

    final plot = Rect.fromLTRB(_left, _top, size.width, size.height - _bottom);
    final top = [...quizzes, ...notes].reduce(math.max);
    final maxY = _niceMax(top);

    double xOf(int i) => plot.left + plot.width * i / (count - 1);
    double yOf(num v) => plot.bottom - plot.height * v / maxY;

    // Grid lines + y labels (0, 1/3, 2/3, max).
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var step = 0; step <= 3; step++) {
      final value = (maxY * step / 3).round();
      final y = yOf(value);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        Formatters.thousands(value),
        axisStyle,
        Offset(plot.left - 8, y),
        align: Alignment.centerRight,
      );
    }

    // X labels: every other day, plus the last one.
    for (var i = 0; i < count; i++) {
      if (i.isOdd && i != count - 1) continue;
      _text(
        canvas,
        activity.dayLabels[i],
        axisStyle,
        Offset(xOf(i), plot.bottom + 8),
        align: Alignment.topCenter,
      );
    }

    Path line(List<int> values) {
      final path = Path()..moveTo(xOf(0), yOf(values[0]));
      for (var i = 1; i < values.length; i++) {
        path.lineTo(xOf(i), yOf(values[i]));
      }
      return path;
    }

    // Quizzes: area + solid line.
    final quizzesLine = line(quizzes);
    final area = Path.from(quizzesLine)
      ..lineTo(xOf(count - 1), plot.bottom)
      ..lineTo(xOf(0), plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(plot.topCenter, plot.bottomCenter, [
          ActivityChartCard.quizzesColor.withValues(alpha: 0.22),
          ActivityChartCard.quizzesColor.withValues(alpha: 0.02),
        ]),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      quizzesLine,
      stroke..color = ActivityChartCard.quizzesColor,
    );

    // Notes generated: dashed line.
    canvas.drawPath(
      _dashed(line(notes)),
      stroke..color = ActivityChartCard.notesColor,
    );

    // Highlighted day: guide line, dots and tooltip.
    final hx = xOf(highlighted);
    canvas.drawLine(
      Offset(hx, plot.top),
      Offset(hx, plot.bottom),
      grid..color = gridColor,
    );
    for (final (value, color) in [
      (notes[highlighted], ActivityChartCard.notesColor),
      (quizzes[highlighted], ActivityChartCard.quizzesColor),
    ]) {
      final center = Offset(hx, yOf(value));
      canvas.drawCircle(center, 6, Paint()..color = AppColors.white);
      canvas.drawCircle(center, 4, Paint()..color = color);
    }
    _tooltip(
      canvas,
      '${activity.dayLabels[highlighted]}: '
      '${Formatters.thousands(quizzes[highlighted])} quizzes · '
      '${Formatters.thousands(notes[highlighted])} notes',
      Offset(hx, yOf(quizzes[highlighted]) - 12),
      size.width,
    );
  }

  /// A round number a bit above [value], so the line does not touch the top.
  static double _niceMax(int value) {
    if (value <= 0) return 1;
    final padded = value * 1.1;
    final magnitude = math
        .pow(10, (math.log(padded) / math.ln10).floor() - 1)
        .toDouble();
    return (padded / magnitude).ceil() * magnitude;
  }

  static Path _dashed(Path source, {double dash = 6, double gap = 4}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        result.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    return result;
  }

  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset anchor, {
    required Alignment align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    // Alignment -1..1 -> shift by 0..full size.
    final dx = anchor.dx - painter.width * (align.x + 1) / 2;
    final dy = anchor.dy - painter.height * (align.y + 1) / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  void _tooltip(Canvas canvas, String text, Offset bottomCenter, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: tooltipStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final boxWidth = painter.width + padding.horizontal;
    final boxHeight = painter.height + padding.vertical;
    // Keep the tooltip inside the chart.
    final left = (bottomCenter.dx - boxWidth / 2).clamp(0.0, width - boxWidth);
    final top = math.max(0.0, bottomCenter.dy - boxHeight);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(box, Paint()..color = AppColors.ink);
    painter.paint(canvas, Offset(left + padding.left, top + padding.top));
  }

  @override
  bool shouldRepaint(_ActivityPainter old) =>
      old.activity != activity ||
      old.highlighted != highlighted ||
      old.axisStyle != axisStyle ||
      old.gridColor != gridColor;
}
