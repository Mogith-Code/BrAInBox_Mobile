import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// A white card with a title row ("Recent reports", "Open queue ->") and
/// content below. Used by every section of the dashboard.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;

  /// Shown on the right of the title (a legend, a link, a note...).
  final Widget? trailing;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
