import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The look of an [AppButton].
enum AppButtonVariant {
  /// Solid indigo. The main action on a screen.
  primary,

  /// Indigo outline. A second, less important action.
  secondary,

  /// Text only. For "Skip", "Cancel", links...
  ghost,

  /// Brand gradient (teal -> indigo). For hero actions like "Generate with AI".
  gradient,
}

/// The standard BrAInBox button.
///
/// ```dart
/// AppButton(label: 'Sign in', onPressed: _submit, isLoading: state.isLoading)
/// ```
/// While [isLoading] is true the button shows a spinner and ignores taps.
/// Pass `onPressed: null` to disable it.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width (default). Set to false for inline buttons.
  final bool expand;

  /// Icon after the label, e.g. `Icons.arrow_forward` for "Continue →".
  final IconData? trailingIcon;

  static const Size _minSize = Size(64, 52);

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final List<BoxShadow> _glow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );
    final content = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      trailingIcon: trailingIcon,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => DecoratedBox(
        // Soft indigo glow under enabled primary buttons (as in Figma).
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: onTap == null ? null : _glow,
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.surfaceMuted,
            disabledForegroundColor: AppColors.muted,
            minimumSize: _minSize,
            shape: shape,
            textStyle: _labelStyle,
          ),
          child: content,
        ),
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: _minSize,
          shape: shape,
        ),
        child: content,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: _minSize,
          shape: shape,
        ),
        child: content,
      ),
      AppButtonVariant.gradient => _GradientButton(
        onPressed: onTap,
        shape: shape,
        child: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A [FilledButton] drawn on top of the brand gradient.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.shape,
    required this.child,
  });

  final VoidCallback? onPressed;
  final RoundedRectangleBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: AppColors.white,
            disabledForegroundColor: AppColors.white,
            shadowColor: Colors.transparent,
            minimumSize: AppButton._minSize,
            shape: shape,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Spinner or icon + label. Colors come from the parent button.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.trailingIcon,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 20),
        ],
      ],
    );
  }
}
