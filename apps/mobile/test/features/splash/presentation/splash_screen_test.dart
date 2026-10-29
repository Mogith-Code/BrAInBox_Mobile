import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/router.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/splash/presentation/splash_screen.dart';
import 'package:brainbox_mobile/features/splash/presentation/widgets/splash_decorations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_app.dart';

void main() {
  testWidgets('shows the logo, tagline and loader while loading', (
    tester,
  ) async {
    final c = fakeContainer(
      overrides: [
        // A session that never finishes loading.
        sessionProvider.overrideWith(_NeverLoads.new),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(AppLogo), findsNWidgets(2)); // icon + wordmark
    expect(find.text('BrAInBox', findRichText: true), findsOneWidget);
    expect(find.text('Study smarter. Fix what matters.'), findsOneWidget);
    expect(find.byType(LoadingDots), findsOneWidget);
  });

  testWidgets('error state shows the message and Retry', (tester) async {
    final c = fakeContainer(
      overrides: [sessionProvider.overrideWith(_Fails.new)],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Check it and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('redirects to the welcome carousel on first launch', (
    tester,
  ) async {
    final c = fakeContainer(welcomeSeen: false);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: c.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learn smarter'), findsOneWidget);
  });
}

class _NeverLoads extends Session {
  @override
  Future<SessionState> build() => Completer<SessionState>().future;
}

class _Fails extends Session {
  @override
  Future<SessionState> build() async =>
      throw const ApiException(code: 'network', message: 'offline');
}
