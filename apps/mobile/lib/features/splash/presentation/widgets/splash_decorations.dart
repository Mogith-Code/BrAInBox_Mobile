import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// The faint shapes floating on the splash gradient (Figma A1): an "eye"
/// ring, dots, a little node graph, a leaf and an amber sparkle.
/// Purely decorative.
class SplashDecorations extends StatelessWidget {
  const SplashDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox.expand(child: CustomPaint(painter: _DecorPainter())),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  const _DecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final faint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // "Eye" ring, top left.
    final eye = Rect.fromCenter(
      center: Offset(w * 0.145, h * 0.12),
      width: 50,
      height: 38,
    );
    canvas.drawOval(eye, faint);
    canvas.drawCircle(
      eye.center,
      7,
      Paint()..color = AppColors.white.withValues(alpha: 0.35),
    );

    // Small amber dot near the top.
    canvas.drawCircle(
      Offset(w * 0.51, h * 0.16),
      4,
      Paint()..color = AppColors.amber.withValues(alpha: 0.7),
    );

    // Node graph, right side.
    final node = Paint()..color = AppColors.white.withValues(alpha: 0.35);
    final line = Paint()
      ..color = AppColors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final n1 = Offset(w * 0.86, h * 0.205);
    final n2 = Offset(w * 0.83, h * 0.23);
    final n3 = Offset(w * 0.89, h * 0.23);
    final n4 = Offset(w * 0.82, h * 0.255);
    final n5 = Offset(w * 0.89, h * 0.255);
    canvas.drawLine(n2, n3, line);
    canvas.drawLine(n4, n5, line);
    for (final n in [n1, n2, n3, n4, n5]) {
      canvas.drawCircle(n, 4, node);
    }
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.275),
      4,
      Paint()..color = AppColors.mint.withValues(alpha: 0.5),
    );

    // Lavender dot by the wordmark.
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.58),
      6,
      Paint()..color = AppColors.primaryLight.withValues(alpha: 0.6),
    );

    // Amber sparkle under it.
    _sparkle(canvas, Offset(w * 0.82, h * 0.655), 15, AppColors.amber);

    // Leaf, bottom left.
    canvas.save();
    canvas.translate(w * 0.18, h * 0.72);
    canvas.rotate(-0.7);
    final leaf = Path()
      ..moveTo(-20, 0)
      ..quadraticBezierTo(0, -16, 20, 0)
      ..quadraticBezierTo(0, 16, -20, 0)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()..color = AppColors.mint.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.15, c.dy - r * 0.15, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.15, c.dy + r * 0.15, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.15, c.dy + r * 0.15, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.15, c.dy - r * 0.15, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three white dots that pulse one after another (the splash loader).
/// Static when the system asks for reduced motion.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Opacity(
                opacity: _opacityFor(i),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _opacityFor(int i) {
    if (!_controller.isAnimating) return 1;
    final t = (_controller.value * 3 - i) % 3;
    return t < 1 ? 1 : 0.45;
  }
}
