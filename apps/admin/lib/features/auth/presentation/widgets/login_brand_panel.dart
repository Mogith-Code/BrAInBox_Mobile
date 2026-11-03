import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/admin_logo.dart';

/// The gradient panel on the left of the login page (wide screens only):
/// logo, headline, three stat tiles and the access notice.
class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key});

  /// The stat tiles under the headline.
  ///
  // TODO(mogith): the Figma mock shows sample figures (14, 2,418, 96.2%).
  // Show real numbers here only once an endpoint provides them; until then
  // the tiles show a dash so nobody mistakes mock figures for live data.
  static const List<({String value, String label})> stats = [
    (value: '—', label: 'AI items to review'),
    (value: '—', label: 'active students'),
    (value: '—', label: 'eval. accuracy'),
  ];

  static const Color _textOnDark = AppColors.taglineOnDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          // Decorative "circuit" lines. Hidden from screen readers.
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _CircuitPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminLogo(onDark: true),
                const Spacer(),
                Text(
                  'CONTENT & QUALITY CONSOLE',
                  style: textTheme.labelMedium?.copyWith(
                    color: _textOnDark,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'Every answer a student sees passes through here.',
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final stat in stats)
                      _StatTile(value: stat.value, label: stat.label),
                  ],
                ),
                const Spacer(),
                Text(
                  'Restricted to approved teachers and moderators · '
                  'All actions are logged',
                  style: textTheme.bodySmall?.copyWith(color: _textOnDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        width: 136,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: LoginBrandPanel._textOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint horizontal lines with a dot at one end and a ring at the other,
/// like the decoration in the Figma mock.
class _CircuitPainter extends CustomPainter {
  const _CircuitPainter();

  /// (y, startX, endX) as fractions of the panel size.
  static const List<(double, double, double)> _lines = [
    (0.18, 0.64, 0.89),
    (0.22, 0.73, 0.81),
    (0.25, 0.71, 0.82),
    (0.28, 0.72, 0.82),
    (0.32, 0.74, 0.81),
    (0.35, 0.64, 0.89),
    (0.42, 0.55, 1.00),
    (0.48, 0.60, 1.00),
    (0.53, 0.72, 0.84),
    (0.56, 0.70, 0.82),
    (0.59, 0.72, 0.82),
    (0.62, 0.74, 0.81),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final color = AppColors.white.withValues(alpha: 0.3);
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final dot = Paint()..color = color;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final (y, startX, endX) in _lines) {
      final start = Offset(size.width * startX, size.height * y);
      final end = Offset(size.width * endX, size.height * y);
      canvas.drawLine(start, end, line);
      canvas.drawCircle(start, 4, dot);
      if (endX < 1) canvas.drawCircle(end, 4, ring);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) => false;
}
