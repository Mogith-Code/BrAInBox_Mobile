import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:brainbox_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:brainbox_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the welcome screen inside a tiny router so we can see where the
/// buttons go.
Future<GoRouter> _pump(WidgetTester tester, ProviderContainer container) async {
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => const Scaffold(body: Text('SIGN UP')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('LOG IN')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the first slide and swipes to the next', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Learn smarter'), findsOneWidget);
    expect(find.text('AI-generated'), findsOneWidget); // AiBadge on slide 1
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account · Log in'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Know exactly what went wrong'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text("Always know what's next"), findsOneWidget);
  });

  testWidgets('Get Started saves the flag and opens sign up', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('SIGN UP'), findsOneWidget);
    expect(await OnboardingRepository().isWelcomeSeen(), isTrue);
    expect(container.read(welcomeSeenProvider).value, isTrue);
  });

  testWidgets('Log in saves the flag and opens log in', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('I already have an account · Log in'));
    await tester.pumpAndSettle();

    expect(find.text('LOG IN'), findsOneWidget);
    expect(await OnboardingRepository().isWelcomeSeen(), isTrue);
  });

  testWidgets('fits a small 360x640 screen with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container);
    expect(tester.takeException(), isNull);
  });
}
