import 'dart:math' as math;

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/analytics_controller.dart';
import '../domain/analytics_models.dart';

/// Analytics: daily active students, AI feature usage, average mastery per
/// unit and the most common misconceptions, for 7d / 30d / 90d / a term.
///
/// Route: `/analytics`. Data: `/admin/analytics/overview`, `/performance`,
/// `/ai-usage` (built on the backend).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeControllerProvider);
    final state = ref.watch(analyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: 'Learning outcomes & platform health',
          title: 'Analytics',
          actions: [
            SegmentedButton<AnalyticsRange>(
              segments: [
                for (final r in AnalyticsRange.values)
                  ButtonSegment(value: r, label: Text(r.label)),
              ],
              selected: {range},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ref
                  .read(analyticsRangeControllerProvider.notifier)
                  .set(s.first),
            ),
          ],
        ),
        Expanded(
          child: switch (state) {
            AsyncData(:final value) => _Body(data: value),
            AsyncError(:final error) => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(analyticsProvider),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final o = data.overview;
    final change = o.activeChangePercent;
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);

    final usage = AdminPanel(
      title: 'Usage over time · daily active students',
      trailing: change == null
          ? null
          : Text(
              '${change >= 0 ? '↗ +' : '↘ '}${change.toStringAsFixed(0)}% vs before',
              style: TextStyle(
                color: change >= 0 ? AppColors.successDark : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
      child: SizedBox(
        height: 220,
        child: o.dailyActiveStudents.isEmpty
            ? Center(child: Text('No activity yet.', style: muted))
            : CustomPaint(
                painter: _LinePainter([
                  for (final d in o.dailyActiveStudents) d.count.toDouble(),
                ]),
                child: const SizedBox.expand(),
              ),
      ),
    );
    final ai = AdminPanel(
      title: 'AI feature usage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, f) in data.ai.byFeature.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 5,
                    backgroundColor: _palette[i % _palette.length],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(featureLabel(f.feature))),
                  Text(
                    '${f.percent.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Divider(),
          Text(
            '${Formatters.thousands(data.ai.totalRequests)} AI requests · '
            '${Formatters.thousands(data.ai.images)} images',
            style: muted,
          ),
        ],
      ),
    );
    final mastery = AdminPanel(
      title: 'Average mastery by unit',
      child: Column(
        children: [
          for (final u in data.performance.units)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      'U${u.number} ${u.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: u.averageMastery == null
                        ? Text('Not assessed yet', style: muted)
                        : LinearProgressIndicator(
                            value: u.averageMastery! / 100,
                            minHeight: 8,
                            color: u.averageMastery! < 50
                                ? AppColors.warning
                                : AppColors.primary,
                            backgroundColor: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      u.averageMastery == null
                          ? ''
                          : '${u.averageMastery!.round()}%${u.averageMastery! < 50 ? ' ⚠' : ''}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    final misconceptions = AdminPanel(
      title: 'Common misconceptions',
      child: data.performance.misconceptions.isEmpty
          ? Text('None recorded in this period.', style: muted)
          : Column(
              children: [
                for (final (i, m) in data.performance.misconceptions.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: i < 3
                          ? AppColors.ink
                          : AppColors.surfaceMuted,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i < 3 ? AppColors.white : AppColors.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(m.title),
                    trailing: Text(Formatters.thousands(m.timesChosen)),
                  ),
              ],
            ),
    );

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 1000;
          Widget pair(Widget a, Widget b, {int flexA = 3, int flexB = 2}) =>
              wide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: flexA, child: a),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: flexB, child: b),
                    ],
                  ),
                )
              : Column(
                  children: [
                    a,
                    const SizedBox(height: AppSpacing.lg),
                    b,
                  ],
                );
          return Column(
            children: [
              pair(usage, ai),
              const SizedBox(height: AppSpacing.lg),
              pair(mastery, misconceptions, flexA: 1, flexB: 1),
            ],
          );
        },
      ),
    );
  }

  static const _palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.mint,
    AppColors.warning,
    AppColors.mutedLight,
  ];

  /// Backend feature names -> what admins call them.
  static String featureLabel(String feature) => switch (feature) {
    'notes' => 'AI notes',
    'tutor' => 'Ask BrAInBox',
    'visuals' => 'Visual generator',
    'evaluation' => 'Handwriting eval.',
    'upload' || 'summaries' => 'Upload summaries',
    'questions' => 'Question generation',
    _ => feature[0].toUpperCase() + feature.substring(1),
  };
}

/// A simple filled line chart (no chart package in the admin app).
class _LinePainter extends CustomPainter {
  _LinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max) * 1.1;
    Offset at(int i) => Offset(
      size.width * i / (values.length - 1),
      size.height - (maxV == 0 ? 0 : values[i] / maxV * size.height),
    );
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = size.height * g / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}
