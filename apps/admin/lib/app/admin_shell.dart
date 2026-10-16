import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import 'router.dart';

/// One entry in the sidebar.
typedef AdminNavItem = ({String label, IconData icon, String path});

/// Layout for every admin page: a left sidebar and a top bar.
///
/// - Wide screens (>= 1000 px): expanded sidebar with the horizontal logo.
/// - Medium screens (700 - 1000 px): collapsed sidebar (icons + logo icon).
/// - Small screens: the sidebar moves into a drawer; the top bar shows the
///   logo icon next to the page title.
///
// TODO(samni): match the admin layout in Figma.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  /// The current path, used to highlight the sidebar item.
  final String location;

  /// The page to show.
  final Widget child;

  /// Sidebar items, in order. Add a line here when you add a page.
  static const List<AdminNavItem> navItems = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: AdminRoutes.dashboard,
    ),
    (
      label: 'Syllabus manager',
      icon: Icons.account_tree_outlined,
      path: AdminRoutes.syllabus,
    ),
    (
      label: 'Content review',
      icon: Icons.fact_check_outlined,
      path: AdminRoutes.contentReview,
    ),
    (
      label: 'Question bank',
      icon: Icons.quiz_outlined,
      path: AdminRoutes.questionBank,
    ),
    (label: 'MCQ mapping', icon: Icons.alt_route, path: AdminRoutes.mcqMapping),
    (
      label: 'Quality review',
      icon: Icons.rule,
      path: AdminRoutes.qualityReview,
    ),
    (
      label: 'Past papers',
      icon: Icons.description_outlined,
      path: AdminRoutes.pastPapers,
    ),
    (
      label: 'Knowledge base',
      icon: Icons.menu_book_outlined,
      path: AdminRoutes.knowledgeBase,
    ),
    (
      label: 'RAG sources',
      icon: Icons.source_outlined,
      path: AdminRoutes.ragSources,
    ),
    (
      label: 'Moderation',
      icon: Icons.shield_outlined,
      path: AdminRoutes.moderation,
    ),
    (label: 'Users', icon: Icons.people_outline, path: AdminRoutes.users),
    (
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      path: AdminRoutes.analytics,
    ),
  ];

  static const double _wideBreakpoint = 1000;
  static const double _mediumBreakpoint = 700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );
    final title = selected >= 0 ? navItems[selected].label : 'BrAInBox Admin';
    final signOut = IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Small: drawer + app bar with the logo icon.
        if (width < _mediumBreakpoint) {
          return Scaffold(
            appBar: AppBar(title: BrandAppBarTitle(title), actions: [signOut]),
            drawer: Drawer(
              child: _Sidebar(selectedIndex: selected, closeDrawerOnTap: true),
            ),
            body: child,
          );
        }

        // Medium: collapsed sidebar. Wide: expanded sidebar.
        final collapsed = width < _wideBreakpoint;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: collapsed ? 80 : 260,
                child: _Sidebar(selectedIndex: selected, collapsed: collapsed),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(title: title, trailing: signOut),
                    const Divider(height: 1),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    this.collapsed = false,
    this.closeDrawerOnTap = false,
  });

  final int selectedIndex;

  /// Icons only, with the logo icon at the top.
  final bool collapsed;

  /// Close the drawer after a tap (small screens).
  final bool closeDrawerOnTap;

  void _open(BuildContext context, String path) {
    if (closeDrawerOnTap) Scaffold.of(context).closeDrawer();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    const items = AdminShell.navItems;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Brand: horizontal logo when expanded, icon when collapsed.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: collapsed ? Alignment.center : Alignment.centerLeft,
                child: collapsed
                    ? const AppLogo(size: 32)
                    : const AppLogo(
                        variant: AppLogoVariant.horizontal,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < items.length; i++)
              if (collapsed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: IconButton(
                    tooltip: items[i].label,
                    isSelected: i == selectedIndex,
                    icon: Icon(items[i].icon),
                    color: i == selectedIndex ? AppColors.primary : null,
                    style: IconButton.styleFrom(
                      backgroundColor: i == selectedIndex
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                    onPressed: () => _open(context, items[i].path),
                  ),
                )
              else
                ListTile(
                  leading: Icon(items[i].icon),
                  title: Text(items[i].label),
                  selected: i == selectedIndex,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  onTap: () => _open(context, items[i].path),
                ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
