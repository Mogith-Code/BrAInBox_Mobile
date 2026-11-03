import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// Top of the dashboard: date + batch, greeting, and the search /
/// notifications / export actions.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.now,
    required this.firstName,
    required this.batchLabel,
    required this.onSearch,
    required this.onNotifications,
    required this.onExport,
  });

  /// Today (passed in so tests can fix the date and time).
  final DateTime now;

  /// The signed-in admin's first name, or null to greet without a name.
  final String? firstName;
  final String batchLabel;
  final ValueChanged<String> onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onExport;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Tuesday, 7 October 2026"
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} '
      '${_months[date.month - 1]} ${date.year}';

  /// "Good morning" / "Good afternoon" / "Good evening"
  static String greeting(DateTime time) => switch (time.hour) {
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateLine = [
      longDate(now),
      if (batchLabel.isNotEmpty) batchLabel,
    ].join(' · ');
    final name = firstName;
    final hello = name == null || name.isEmpty
        ? greeting(now)
        : '${greeting(now)}, $name';

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLine,
          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(hello, style: textTheme.headlineSmall),
        ),
      ],
    );

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            onSubmitted: onSearch,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search anything',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none),
          style: IconButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Side by side when there is room, otherwise actions go below.
        if (constraints.maxWidth >= 860) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.lg),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: AppSpacing.lg),
            actions,
          ],
        );
      },
    );
  }
}
