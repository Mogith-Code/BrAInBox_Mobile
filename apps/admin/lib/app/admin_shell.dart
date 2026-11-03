import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../widgets/admin_logo.dart';
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
/// The page itself is padded and limited to [maxContentWidth], so screens
/// should not add their own outer padding.
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

  /// The widest a page's content gets on large monitors.
  static const double maxContentWidth = 1280;

  static const double _wideBreakpoint = 1000;
  static const double _mediumBreakpoint = 700;

  /// Height of the logo header above the sidebar items.
  static const double _logoHeight = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );
    final title = selected >= 0 ? navItems[selected].label : 'BrAInBox Admin';
    void signOut() => ref.read(authControllerProvider.notifier).signOut();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Small: drawer + app bar with the logo icon.
        if (width < _mediumBreakpoint) {
          return Scaffold(
            appBar: AppBar(title: BrandAppBarTitle(title)),
            drawer: Drawer(
              child: _Sidebar(
                selectedIndex: selected,
                onSignOut: signOut,
                closeDrawerOnTap: true,
              ),
            ),
            body: _PageBody(padding: AppSpacing.lg, child: child),
          );
        }

        // Medium: collapsed sidebar. Wide: expanded sidebar.
        // No top bar: each page shows its own header, and sign-out is at the
        // bottom of the sidebar.
        final collapsed = width < _wideBreakpoint;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: collapsed ? 80 : 260,
                child: _Sidebar(
                  selectedIndex: selected,
                  onSignOut: signOut,
                  collapsed: collapsed,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _PageBody(padding: AppSpacing.xl, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pads the page and keeps it at most [AdminShell.maxContentWidth] wide,
/// centred at the top.
class _PageBody extends StatelessWidget {
  const _PageBody({required this.padding, required this.child});

  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AdminShell.maxContentWidth),
        // Fill the available width and height, so pages that use Center or
        // ListView behave the same as without the max width.
        child: SizedBox.expand(
          child: Padding(padding: EdgeInsets.all(padding), child: child),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onSignOut,
    this.collapsed = false,
    this.closeDrawerOnTap = false,
  });

  final int selectedIndex;
  final VoidCallback onSignOut;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand: logo + "ADMIN" when expanded, icon when collapsed.
            SizedBox(
              height: AdminShell._logoHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : AppSpacing.xl,
                ),
                child: Align(
                  alignment: collapsed
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: collapsed
                      ? const AppLogo(size: 32)
                      // Shrinks instead of overflowing with larger fonts.
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AdminLogo(),
                        ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                container: true,
                label: 'Admin navigation',
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: collapsed
                            ? _NavIconButton(
                                item: items[i],
                                selected: i == selectedIndex,
                                onTap: () => _open(context, items[i].path),
                              )
                            : _NavTile(
                                item: items[i],
                                selected: i == selectedIndex,
                                onTap: () => _open(context, items[i].path),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            _SidebarFooter(collapsed: collapsed, onSignOut: onSignOut),
          ],
        ),
      ),
    );
  }
}

/// Light indigo fill behind the selected sidebar item.
final Color _selectedFill = AppColors.primary.withValues(alpha: 0.08);

/// One sidebar item with an icon and a label (expanded sidebar and drawer).
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(item.icon, size: 22),
      title: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onTap: onTap,
      minTileHeight: 44,
      horizontalTitleGap: AppSpacing.md,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      iconColor: AppColors.muted,
      textColor: Theme.of(context).colorScheme.onSurface,
      selectedColor: AppColors.primary,
      selectedTileColor: _selectedFill,
      titleTextStyle: textTheme.labelLarge?.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}

/// One sidebar item as an icon only (collapsed sidebar). The label is shown
/// as a tooltip and read by screen readers.
class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: item.label,
        isSelected: selected,
        icon: Icon(item.icon),
        color: selected ? AppColors.primary : AppColors.muted,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(48),
          backgroundColor: selected ? _selectedFill : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

/// Bottom of the sidebar: the signed-in admin and the sign-out button.
///
/// Collapsed: only the sign-out icon. When nobody is signed in (Firebase not
/// configured, or the auth guard disabled) no user is shown - never a made-up
/// one.
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({required this.collapsed, required this.onSignOut});

  final bool collapsed;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signOut = IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
      color: AppColors.muted,
      onPressed: onSignOut,
    );
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(child: signOut),
      );
    }

    final user = ref.watch(currentUserProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final name = user?.fullName.trim() ?? '';
    final primaryText = user == null
        ? 'Not signed in'
        : (name.isNotEmpty ? name : user.email);
    final initials = _initials(name.isNotEmpty ? name : user?.email ?? '');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            if (user != null) ...[
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.18),
                  child: Text(
                    initials,
                    style: textTheme.labelLarge?.copyWith(color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user != null)
                    Text(
                      name.isNotEmpty ? user.email : user.role,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            signOut,
          ],
        ),
      ),
    );
  }

  /// "Tharushi Silva" -> "TS", "a@b.lk" -> "A".
  static String _initials(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
