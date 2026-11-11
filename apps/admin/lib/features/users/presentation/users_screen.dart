import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/users_controller.dart';
import '../domain/users_models.dart';

/// Students: search, filter, see mastery and last activity, and suspend or
/// reinstate an account.
///
/// Route: `/users`. Data: `GET /admin/users`, `PATCH /admin/users/{id}`.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  static const _examYears = [2025, 2026, 2027, 2028];
  static const _districts = [
    'Colombo',
    'Galle',
    'Jaffna',
    'Kandy',
    'Kurunegala',
    'Matara',
    'Negombo',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersControllerProvider);
    final filter = ref.watch(studentFilterControllerProvider);
    final setFilter = ref.read(studentFilterControllerProvider.notifier).set;
    final page = state.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: page == null
              ? null
              : '${Formatters.thousands(page.activeTotal)} active · '
                    '${Formatters.thousands(page.total)} total',
          title: 'Students',
          actions: [
            TextButton.icon(
              onPressed: page == null
                  ? null
                  : () => showAdminSnack(
                      context,
                      'CSV export needs GET /admin/users/export.csv.',
                    ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Name, email or school',
                ),
                onSubmitted: (v) => setFilter(filter.copyWith(search: v)),
              ),
            ),
            FilterDropdown<int?>(
              label: 'Exam year',
              value: filter.examYear,
              options: const [null, ..._examYears],
              labelOf: (y) => y?.toString() ?? 'All',
              onChanged: (y) => setFilter(filter.copyWith(examYear: y)),
            ),
            FilterDropdown<StudentStatus?>(
              label: 'Status',
              value: filter.status,
              options: const [null, ...StudentStatus.values],
              labelOf: (s) => s?.label ?? 'Any',
              onChanged: (s) => setFilter(filter.copyWith(status: s)),
            ),
            FilterDropdown<String?>(
              label: 'District',
              value: filter.district,
              options: const [null, ..._districts],
              labelOf: (d) => d ?? 'All',
              onChanged: (d) => setFilter(filter.copyWith(district: d)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: switch (state) {
            AsyncData(:final value) => _Table(students: value.items),
            AsyncError(:final error) => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(usersControllerProvider),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _Table extends ConsumerWidget {
  const _Table({required this.students});

  final List<AdminStudent> students;

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    AdminStudent s,
  ) async {
    final suspend = s.status != StudentStatus.suspended;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          suspend ? 'Suspend ${s.fullName}?' : 'Reinstate ${s.fullName}?',
        ),
        content: Text(
          suspend
              ? 'They will be signed out and cannot use BrAInBox until you '
                    'reinstate them.'
              : 'They can sign in and study again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(suspend ? 'Suspend' : 'Reinstate'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final saved = await ref
        .read(usersControllerProvider.notifier)
        .setActive(s.id, active: !suspend);
    if (!saved && context.mounted) {
      showAdminSnack(context, "Couldn't update ${s.fullName}. Try again.");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No students match',
        message: 'Try another search or clear the filters.',
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return AdminPanel(
      padding: EdgeInsets.zero,
      child: Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1100,
            child: ListView.separated(
              itemCount: students.length + 1,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const _Row(
                    cells: [
                      TableHeading('Student'),
                      TableHeading('School'),
                      TableHeading('A/L year'),
                      TableHeading('Avg. mastery'),
                      TableHeading('Status'),
                      TableHeading('Last active'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TableHeading('Actions'),
                      ),
                    ],
                  );
                }
                final s = students[i - 1];
                final suspended = s.status == StudentStatus.suspended;
                return _Row(
                  cells: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            Formatters.initials(s.fullName),
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                s.email,
                                overflow: TextOverflow.ellipsis,
                                style: muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text([?s.district, ?s.school].join(' · '), style: muted),
                    Text(s.examYear?.toString() ?? '—'),
                    _MasteryBar(value: s.avgMastery),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(
                        label: s.status.label,
                        tone: switch (s.status) {
                          StudentStatus.active => BadgeTone.success,
                          StudentStatus.suspended => BadgeTone.danger,
                          StudentStatus.inactive => BadgeTone.neutral,
                        },
                      ),
                    ),
                    Text(
                      s.lastActiveAt == null
                          ? 'Never'
                          : Formatters.relativeTime(s.lastActiveAt!),
                      style: muted,
                    ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showProfile(context, s),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View profile'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: suspended
                                ? AppColors.successDark
                                : AppColors.error,
                          ),
                          onPressed: () => _toggle(context, ref, s),
                          icon: Icon(
                            suspended ? Icons.check : Icons.person_off_outlined,
                            size: 16,
                          ),
                          label: Text(suspended ? 'Reinstate' : 'Suspend'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context, AdminStudent s) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.email),
            Text([?s.school, ?s.district].join(', ')),
            Text('A/L ${s.examYear ?? '—'}'),
            Text(
              s.avgMastery == null
                  ? 'Mastery: not assessed yet'
                  : 'Average mastery: ${s.avgMastery}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.cells});

  final List<Widget> cells;

  static const _flex = [5, 4, 2, 4, 3, 3, 6];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  const _MasteryBar({required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null) {
      return Text(
        'Not assessed',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      );
    }
    final color = v >= 70
        ? AppColors.secondary
        : v >= 50
        ? AppColors.primary
        : AppColors.warning;
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: v / 100,
            minHeight: 6,
            color: color,
            backgroundColor: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('$v%'),
      ],
    );
  }
}
