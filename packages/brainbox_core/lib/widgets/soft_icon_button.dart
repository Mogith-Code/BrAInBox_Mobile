import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A 44x44 icon button on a soft indigo square (header actions, back).
///
/// ```dart
/// SoftIconButton(
///   icon: Icons.bookmark_border,
///   selectedIcon: Icons.bookmark,
///   isSelected: saved,
///   tooltip: 'Save to My library',
///   onPressed: toggle,
/// )
/// ```
/// On dark headers pass [background] and [foreground], e.g. translucent
/// white with a white icon.
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.isSelected,
    this.background = AppColors.primarySoft,
    this.foreground = AppColors.primary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Icon shown while [isSelected] is true (e.g. a filled bookmark).
  final IconData? selectedIcon;

  /// Null = not a toggle button.
  final bool? isSelected;

  final Color background;
  final Color foreground;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: isSelected,
      icon: Icon(icon, size: 22),
      selectedIcon: selectedIcon == null ? null : Icon(selectedIcon, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        fixedSize: const Size.square(size),
        minimumSize: const Size.square(size),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
