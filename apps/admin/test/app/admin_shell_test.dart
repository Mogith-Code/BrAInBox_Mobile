import 'package:brainbox_admin/app/admin_shell.dart';
import 'package:brainbox_admin/app/router.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Checks the shell layout at each breakpoint, with simple stand-in pages
/// (so the test does not depend on any feature screen).
void main() {
  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AdminRoutes.dashboard,
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              AdminShell(location: state.uri.path, child: child),
          routes: [
            for (final item in AdminShell.navItems)
              GoRoute(
                path: item.path,
                builder: (context, state) => Text('Page ${item.path}'),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide: expanded sidebar with labels; tapping navigates', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1400, 900));

    for (final item in AdminShell.navItems) {
      expect(find.text(item.label), findsWidgets, reason: item.label);
    }
    // Sign-out sits at the bottom of the sidebar (there is no top bar).
    expect(find.byTooltip('Sign out'), findsOneWidget);
    expect(find.text('Page ${AdminRoutes.dashboard}'), findsOneWidget);

    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    expect(find.text('Page ${AdminRoutes.users}'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
  });

  testWidgets('medium: icon-only sidebar with tooltips; tapping navigates', (
    tester,
  ) async {
    await pumpShell(tester, const Size(800, 900));

    // Labels are tooltips only.
    expect(find.text('Users'), findsNothing);
    expect(find.byTooltip('Users'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsOneWidget);

    await tester.tap(find.byTooltip('Users'));
    await tester.pumpAndSettle();

    expect(find.text('Page ${AdminRoutes.users}'), findsOneWidget);
  });

  testWidgets('small: drawer opens, navigates and closes', (tester) async {
    await pumpShell(tester, const Size(500, 900));

    expect(find.byType(Drawer), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    // Sign-out is in the drawer on small screens.
    expect(find.byTooltip('Sign out'), findsOneWidget);

    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Page ${AdminRoutes.users}'), findsOneWidget);
  });
}
