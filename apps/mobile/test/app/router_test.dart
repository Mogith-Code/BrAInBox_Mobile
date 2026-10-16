import 'package:brainbox_mobile/app/router.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens every route in [AppRoutes.catalog] and checks that a screen shows.
/// If you add a route to the catalog but forget the router, this fails.
void main() {
  testWidgets('every route in the catalog opens a screen', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    for (final route in AppRoutes.catalog) {
      router.go(route.path);
      await tester.pumpAndSettle();
      final reason = '${route.title} (${route.path})';
      expect(tester.takeException(), isNull, reason: reason);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        route.path,
        reason: reason,
      );
      expect(find.byType(Scaffold), findsWidgets, reason: reason);
    }
  });
}
