import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// The top of every admin page: a small grey line ("8,942 questions ..."),
/// the page title and the actions on the right (buttons, search...).
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
        ],
      ),
    );
  }
}

/// A white rounded box with an optional title row, used for every section.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || trailing != null) ...[
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// The coloured status chips used in the admin tables.
enum BadgeTone {
  success(
    AppColors.successSoft,
    AppColors.successDark,
    Icons.check_circle_outline,
  ),
  warning(AppColors.warningSoft, AppColors.warningDark, Icons.auto_awesome),
  danger(AppColors.errorSoft, AppColors.error, Icons.cancel_outlined),
  neutral(AppColors.surfaceMuted, AppColors.muted, Icons.edit_outlined),
  info(AppColors.primarySoft, AppColors.primary, Icons.info_outline);

  const BadgeTone(this.background, this.foreground, this.icon);

  final Color background;
  final Color foreground;
  final IconData icon;
}

/// "Approved", "AI-generated · pending review", "Rejected", "Draft"...
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.showIcon = true,
  });

  final String label;
  final BadgeTone tone;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(tone.icon, size: 12, color: tone.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The review status of anything an admin approves (backend ContentStatus).
enum ReviewStatus {
  draft,
  pendingReview,
  approved,
  rejected,
  archived;

  static ReviewStatus fromApi(String? value) => switch (value) {
    'pending_review' => pendingReview,
    'approved' => approved,
    'rejected' => rejected,
    'archived' => archived,
    _ => draft,
  };

  String get apiValue => switch (this) {
    pendingReview => 'pending_review',
    _ => name,
  };
}

/// The badge for a [ReviewStatus]; AI content waiting for review says so.
StatusBadge reviewBadge(ReviewStatus status, {bool aiGenerated = false}) =>
    switch (status) {
      ReviewStatus.approved => const StatusBadge(
        label: 'Approved',
        tone: BadgeTone.success,
      ),
      ReviewStatus.pendingReview => StatusBadge(
        label: aiGenerated ? 'AI-generated · pending review' : 'Pending review',
        tone: BadgeTone.warning,
      ),
      ReviewStatus.rejected => const StatusBadge(
        label: 'Rejected',
        tone: BadgeTone.danger,
      ),
      ReviewStatus.archived => const StatusBadge(
        label: 'Outdated',
        tone: BadgeTone.neutral,
      ),
      ReviewStatus.draft => const StatusBadge(
        label: 'Draft',
        tone: BadgeTone.neutral,
      ),
    };

/// A "Label: Value ⌄" filter button with a menu, like "Status: Any".
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem(value: o, child: Text(labelOf(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            Text(
              labelOf(value),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.expand_more, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// A small table header cell (grey, upper case).
class TableHeading extends StatelessWidget {
  const TableHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// True when the backend answered 404 for a whole endpoint, i.e. that admin
/// area isn't built on the backend yet (not "this item doesn't exist").
bool isEndpointMissing(Object? error) =>
    error is ApiException &&
    error.statusCode == 404 &&
    !error.code.endsWith('_NOT_FOUND');

/// What an admin page shows when loading failed. A missing backend
/// endpoint gets a calm "not connected yet" message instead of an error.
class AdminLoadError extends StatelessWidget {
  const AdminLoadError({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isEndpointMissing(error)) {
      return const EmptyState(
        icon: Icons.construction_outlined,
        title: 'Not connected yet',
        message:
            'The backend for this page is not built yet. Run with '
            '--dart-define=USE_FAKE_API=true to see sample data.',
      );
    }
    return Center(
      child: ErrorBanner(message: ErrorMessages.of(error), onRetry: onRetry),
    );
  }
}

/// Shows a short message at the bottom of the screen.
void showAdminSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
