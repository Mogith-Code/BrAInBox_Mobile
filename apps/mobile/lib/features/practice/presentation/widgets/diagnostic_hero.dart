import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// The illustration card on "Let's find your starting point" (Figma A12):
/// a big indigo ring with a microscope, an "Adaptive" chip and a small DNA
/// helix, on the soft mint -> white -> indigo card.
///
// TODO(udith): swap the drawn DNA / microscope for the Figma export.
class DiagnosticHero extends StatelessWidget {
  const DiagnosticHero({super.key, this.height = 290});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9FAE9), AppColors.white, AppColors.primarySoft],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: 18,
              top: 18,
              child: AiBadge(label: 'Adaptive'),
            ),
            Center(
              child: Container(
                width: height * 0.6,
                height: height * 0.6,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 10),
                ),
                child: Icon(
                  Icons.biotech_outlined,
                  size: height * 0.24,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 14,
              child: SizedBox(
                width: 36,
                height: 72,
                child: CustomPaint(painter: _DnaPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small double helix: two rows of dots with rungs between them.
class _DnaPainter extends CustomPainter {
  const _DnaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 7;
    final rung = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 2;
    for (var i = 0; i < rows; i++) {
      final y = size.height * (i + 0.5) / rows;
      final t = i / (rows - 1);
      final swing = (0.5 - (t * 2 - 1).abs() * 0.5) * size.width * 0.3;
      final left = Offset(size.width * 0.2 + swing, y);
      final right = Offset(size.width * 0.8 - swing, y);
      canvas.drawLine(left, right, rung);
      canvas.drawCircle(left, 3, Paint()..color = AppColors.primaryLight);
      canvas.drawCircle(right, 3, Paint()..color = AppColors.secondary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
