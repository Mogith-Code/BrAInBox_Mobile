import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/home/data/fake_home_repository.dart';
import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/home/presentation/home_screen.dart';
import 'package:brainbox_mobile/features/profile/data/profile_overview_repository.dart';
import 'package:brainbox_mobile/features/profile/domain/profile_overview_models.dart';
import 'package:brainbox_mobile/features/profile/presentation/profile_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

FakeBackend _signedIn() {
  final backend = FakeBackend(latency: Duration.zero);
  backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);
  return backend;
}

Future<FakeProfileOverviewRepository> _pump(
  WidgetTester tester,
  String location,
) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = _signedIn();
  final repo = FakeProfileOverviewRepository(backend);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => HomeScreen(clock: () => DateTime(2026, 10, 7, 19)),
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        builder: (_, _) => const ProfileOverviewScreen(),
      ),
      for (final path in [AppRoutes.settings, AppRoutes.profileSetup])
        GoRoute(
          path: path,
          builder: (_, s) => Scaffold(body: Text('AT ${s.uri.path}')),
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileOverviewRepositoryProvider.overrideWithValue(repo),
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository(backend)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads the backend profile overview JSON', () {
    final p = ProfileOverview.fromJson({
      'full_name': 'Nethmi Perera',
      'streak_days': 12,
      'achievements_total': 18,
      'achievements': [
        {
          'id': 'a',
          'title': 'Genetics fixer',
          'icon': 'genetics_fixer',
          'unlocked': true,
        },
        {'id': 'b', 'title': 'Unit master', 'unlocked': false, 'seen': true},
      ],
    });
    expect(p.unlockedCount, 1);
    expect(p.unseen?.id, 'a');
    expect(p.achievements.last.emoji, '🔒');
  });

  testWidgets('Profile shows stats, achievements and the goal', (tester) async {
    await _pump(tester, AppRoutes.myProfile);

    expect(find.text('Nethmi Perera'), findsOneWidget);
    expect(find.text('Biological Science · A/L 2027'), findsOneWidget);
    expect(find.text('438'), findsOneWidget);
    expect(find.text('topics mastered'), findsOneWidget);
    expect(find.text('4 of 18'), findsOneWidget);
    expect(find.text('Target grade A · 287 days to go'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.profileSetup}'), findsOneWidget);
  });

  testWidgets('Home shows a new achievement once (F8)', (tester) async {
    final repo = await _pump(tester, AppRoutes.home);

    expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
    expect(find.text('Genetics fixer'), findsOneWidget);
    expect(find.text('+150 XP'), findsOneWidget);

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('ACHIEVEMENT UNLOCKED'), findsNothing);

    // Real async: the fake backend's delay is a timer the test clock
    // wouldn't run on its own.
    final again = await tester.runAsync(repo.overview);
    expect(again!.unseen, isNull); // marked seen
  });
}
