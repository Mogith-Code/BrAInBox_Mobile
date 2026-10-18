import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A row of equal-width pill buttons where exactly one is selected
/// (e.g. target grade "✓ A | B | C"). The selected pill is solid indigo
/// with a check mark.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.semanticPrefix = '',
  });

  final List<T> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String Function(T option) labelOf;

  /// Read before each option, e.g. 'Target grade'.
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm + 2),
          Expanded(child: _pill(context, options[i])),
        ],
      ],
    );
  }

  Widget _pill(BuildContext context, T option) {
    final selected = option == value;
    final label = labelOf(option);
    return Semantics(
      button: true,
      selected: selected,
      label: '$semanticPrefix $label'.trim(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected ? AppColors.primary : AppColors.white,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onChanged(option),
            child: SizedBox(
              height: 54,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check, size: 18, color: AppColors.white),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? AppColors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
