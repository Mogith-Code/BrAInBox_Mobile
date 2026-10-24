import 'dart:math' as math;

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/onboarding_models.dart';

// The three welcome illustrations, drawn in Flutter from the Figma frames.
// TODO(mogith): swap for the real Figma exports (SVG) when the designer
// provides them; keep the same card size.

/// The soft mint -> white -> indigo card behind every welcome illustration
/// (also used by the diagnostic intro).
class SoftGradientCard extends StatelessWidget {
  const SoftGradientCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9FAE9), AppColors.white, AppColors.primarySoft],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}

/// Picks the right illustration for a slide.
class WelcomeIllustrationView extends StatelessWidget {
  const WelcomeIllustrationView({super.key, required this.kind});

  final WelcomeIllustration kind;

  @override
  Widget build(BuildContext context) {
    return SoftGradientCard(
      child: switch (kind) {
        WelcomeIllustration.cell => const _CellIllustration(),
        WelcomeIllustration.feedback => const _FeedbackIllustration(),
        WelcomeIllustration.path => const _PathIllustration(),
      },
    );
  }
}

// ---------------------------------------------------------------- slide 1

class _CellIllustration extends StatelessWidget {
  const _CellIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Note card floating in the top-left corner.
        Positioned(
          left: 22,
          top: 34,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 70,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(width: 54, color: AppColors.secondary, height: 5),
                  SizedBox(height: 4),
                  _Line(width: 40),
                  SizedBox(height: 4),
                  _Line(width: 48),
                ],
              ),
            ),
          ),
        ),
        const Center(
          child: SizedBox(
            width: 170,
            height: 140,
            child: CustomPaint(painter: _CellPainter()),
          ),
        ),
        const Positioned(right: 22, bottom: 30, child: AiBadge()),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.width,
    this.color = AppColors.border,
    this.height = 4,
  });

  final double width;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _CellPainter extends CustomPainter {
  const _CellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final cell = Rect.fromCenter(center: c, width: 140, height: 106);

    canvas.drawOval(cell, Paint()..color = const Color(0xFFD7F7EA));
    canvas.drawOval(
      cell,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Nucleus.
    final nucleus = c.translate(-4, -6);
    canvas.drawCircle(nucleus, 23, Paint()..color = AppColors.white);
    canvas.drawCircle(
      nucleus,
      23,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      nucleus.translate(4, -2),
      6,
      Paint()..color = AppColors.primary,
    );

    // Organelles.
    canvas.drawCircle(
      c.translate(-48, -20),
      4,
      Paint()..color = AppColors.secondary,
    );
    canvas.drawCircle(
      c.translate(24, -36),
      2.5,
      Paint()..color = AppColors.primaryLight,
    );
    canvas.drawCircle(
      c.translate(-18, 22),
      3,
      Paint()..color = AppColors.primaryLight,
    );
    final mito = Rect.fromCenter(
      center: c.translate(-42, 18),
      width: 30,
      height: 15,
    );
    canvas.save();
    canvas.translate(mito.center.dx, mito.center.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: mito.width,
        height: mito.height,
      ),
      Paint()..color = AppColors.amber,
    );
    final squiggle = Path()..moveTo(-9, 1);
    for (var i = 0; i < 4; i++) {
      squiggle.relativeQuadraticBezierTo(2.5, i.isEven ? -4 : 4, 5, 0);
    }
    canvas.drawPath(
      squiggle,
      Paint()
        ..color = AppColors.warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
    final vacuole = Rect.fromCenter(
      center: c.translate(36, 22),
      width: 24,
      height: 13,
    );
    canvas.drawOval(vacuole, Paint()..color = AppColors.mint);
    canvas.drawOval(
      vacuole,
      Paint()
        ..color = AppColors.secondaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawSparkle(canvas, c.translate(56, -46), 11, AppColors.amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A four-point sparkle star (the "AI spark" from the logo).
void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
  final p = Path()
    ..moveTo(center.dx, center.dy - r)
    ..quadraticBezierTo(
      center.dx + r * 0.15,
      center.dy - r * 0.15,
      center.dx + r,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx + r * 0.15,
      center.dy + r * 0.15,
      center.dx,
      center.dy + r,
    )
    ..quadraticBezierTo(
      center.dx - r * 0.15,
      center.dy + r * 0.15,
      center.dx - r,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx - r * 0.15,
      center.dy - r * 0.15,
      center.dx,
      center.dy - r,
    )
    ..close();
  canvas.drawPath(p, Paint()..color = color);
}

// ---------------------------------------------------------------- slide 2

class _FeedbackIllustration extends StatelessWidget {
  const _FeedbackIllustration();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          right: 26,
          top: 18,
          child: Icon(
            Icons.biotech_outlined,
            size: 40,
            color: AppColors.primaryLight,
          ),
        ),
        Align(
          alignment: Alignment(0, -0.15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedbackCard(
                  icon: Icons.highlight_off,
                  text: 'Loop of Henle — filtration',
                  color: Color(0xFFF87171),
                  background: AppColors.white,
                ),
                SizedBox(height: 8),
                _FeedbackCard(
                  icon: Icons.check_circle_outline,
                  text: "Bowman's capsule — ultrafiltration",
                  color: AppColors.success,
                  background: AppColors.white,
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: _FeedbackCard(
                    icon: Icons.lightbulb_outline,
                    text: 'Gap: filtration vs reabsorption',
                    color: AppColors.warning,
                    background: AppColors.warningSoft,
                    textColor: AppColors.warningDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
    this.textColor = AppColors.ink,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColor, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- slide 3

class _PathIllustration extends StatelessWidget {
  const _PathIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _PathPainter())),
        Positioned(
          left: 32,
          bottom: 34,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.track_changes,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Next: 5 MCQs',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(size.width * 0.22, size.height * 0.67);
    final b = Offset(size.width * 0.50, size.height * 0.50);
    final c = Offset(size.width * 0.78, size.height * 0.33);

    // Dotted teal line through the three points.
    final dot = Paint()..color = AppColors.secondary;
    for (final (from, to) in [(a, b), (b, c)]) {
      final distance = (to - from).distance;
      final steps = (distance / 9).floor();
      for (var i = 1; i < steps; i++) {
        final t = i / steps;
        final wave = math.sin(t * math.pi) * 6;
        canvas.drawCircle(
          Offset.lerp(from, to, t)!.translate(0, -wave),
          2.2,
          dot,
        );
      }
    }

    canvas.drawCircle(a, 10, Paint()..color = AppColors.border);
    canvas.drawCircle(b, 10, Paint()..color = AppColors.mint);
    canvas.drawCircle(c, 10, Paint()..color = AppColors.primary);
    _drawSparkle(canvas, c.translate(-4, -12), 9, AppColors.amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
