import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/router.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/home/data/fake_home_repository.dart';
import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/profile/data/personal_details_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_overview_repository.dart';
import 'package:brainbox_mobile/features/profile/domain/profile_overview_models.dart';
import 'package:brainbox_mobile/features/profile/presentation/personal_details_screen.dart';
import 'package:brainbox_mobile/features/profile/presentation/profile_overview_screen.dart';
import 'package:brainbox_mobile/features/recommendations/presentation/widgets/open_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A profile with no new badge, so no popup covers the screen.
class _Profile implements ProfileOverviewRepository {
  @override
  Future<ProfileOverview> overview() async =>
      const ProfileOverview(fullName: 'Nethmi Perera');

  @override
  Future<void> markSeen(String achievementId) async {}
}

void main() {
  testWidgets('Home avatar -> Profile -> Edit profile -> Back, no crash', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend(latency: Duration.zero);
    backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);
    final container = ProviderContainer(
      overrides: [
        authGuardEnabledProvider.overrideWithValue(false),
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository(backend)),
        profileOverviewRepositoryProvider.overrideWithValue(_Profile()),
        personalDetailsProvider.overrideWith(
          (ref) async => const PersonalDetails(
            fullName: 'Nethmi Perera',
            phone: '0771234567',
            bio: 'A/L student',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    await tester.tap(find.text('NP'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileOverviewScreen), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PersonalDetailsScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nethmi Perera'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0771234567'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'A/L student'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileOverviewScreen), findsOneWidget);

    // The old link still lands on the same page.
    router.go(AppRoutes.myProfile);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.settingsProfile,
    );
  });

  testWidgets('a full-screen page can open a tab route with openAction', (
    tester,
  ) async {
    Widget page(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.nextSteps,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => openAction(
                context,
                action: 'practice_quiz',
                target: const {},
              ),
              child: const Text('Start'),
            ),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: AppRoutes.home, builder: (_, _) => page('home')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.quizSetup,
                  builder: (_, _) => page('quiz setup'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push(AppRoutes.nextSteps);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('quiz setup'), findsOneWidget);
  });
}
