import 'package:brainbox_admin/app/admin_shell.dart';
import 'package:brainbox_admin/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens every sidebar page and the login page, and checks each one shows.
void main() {
  testWidgets('every admin route opens a screen', (tester) async {
    // A desktop-sized window, so the sidebar layout is used.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(AdminRoutes.login);
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);

    for (final item in AdminShell.navItems) {
      router.go(item.path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: item.path);
      expect(find.text(item.label), findsWidgets, reason: item.path);
    }
  });
}
