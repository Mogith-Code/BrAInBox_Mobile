import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// Learn-tab design tokens on top of the shared theme (`AppColors`,
/// `AppSpacing`, `AppTypography`).
abstract final class LearnStyle {
  static const double cardRadius = AppSpacing.radiusLg; // 16
  static const double buttonRadius = 14;

  /// `0 4 16 rgba(30,27,75,0.06)`
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0F1E1B4B), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Amber highlight behind key terms in notes.
  static const Color highlight = Color(0x80FCD34D);

  /// Mastery ring colour: >75% green, >45% teal, otherwise amber.
  static Color ringColor(double fraction) {
    final percent = fraction * 100;
    if (percent > 75) return AppColors.success;
    if (percent > 45) return AppColors.secondary;
    return AppColors.warning;
  }
}

/// Surface / text colours that follow light and dark mode.
extension LearnColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get learnBackground =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get learnSurface => isDark ? AppColors.darkSurface : AppColors.white;
  Color get learnInk => isDark ? const Color(0xFFF1F5F9) : AppColors.ink;
  Color get learnMuted => isDark ? AppColors.mutedLight : AppColors.muted;
  Color get learnBorder => isDark ? AppColors.darkBorder : AppColors.border;
}

/// White (dark: surface) rounded card with the soft shadow. Tappable when
/// [onTap] is set.
class LearnCard extends StatelessWidget {
  const LearnCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LearnStyle.cardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: context.isDark ? null : LearnStyle.softShadow,
      ),
      child: Material(
        color: color ?? context.learnSurface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: context.learnBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
