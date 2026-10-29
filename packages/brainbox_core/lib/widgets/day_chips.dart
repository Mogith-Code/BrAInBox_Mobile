import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Seven round day chips "Mo Tu We Th Fr Sa Su" (multi-select).
///
/// Values are the backend's day ids: "mon" ... "sun".
class DayChips extends StatelessWidget {
  const DayChips({super.key, required this.selected, required this.onChanged});

  static const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _short = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _long = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: _DayChip(
              short: _short[i],
              long: _long[i],
              selected: selected.contains(days[i]),
              onTap: () {
                final next = {...selected};
                if (!next.remove(days[i])) next.add(days[i]);
                onChanged(next);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.short,
    required this.long,
    required this.selected,
    required this.onTap,
  });

  final String short;
  final String long;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: long,
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: selected ? AppColors.primary : AppColors.white,
          shape: CircleBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  short,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.white : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
