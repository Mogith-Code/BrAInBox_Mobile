import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/router.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/home/data/fake_home_repository.dart';
import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/profile/data/fake_profile_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_overview_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:brainbox_mobile/features/profile/domain/profile_models.dart';
import 'package:brainbox_mobile/features/profile/presentation/profile_overview_screen.dart';
import 'package:brainbox_mobile/features/settings/data/settings_repository.dart';
import 'package:brainbox_mobile/features/settings/presentation/privacy_screen.dart';
import 'package:brainbox_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the setup screen sends.
class _RecordingProfileRepository extends FakeProfileRepository {
  _RecordingProfileRepository(super.backend);

  final patches = <Map<String, dynamic>>[];
  int completes = 0;

  @override
  Future<Profile> update(Map<String, dynamic> fields) {
    patches.add(Map.of(fields));
    return super.update(fields);
  }

  @override
  Future<Profile> complete() {
    completes++;
    return super.complete();
  }
}

/// The real router (redirect off) on a signed-in, onboarded fake student,
/// at phone width 360 dp.
Future<(GoRouter, _RecordingProfileRepository)> _pump(
  WidgetTester tester, {
  String location = AppRoutes.settings,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final backend = FakeBackend(latency: Duration.zero);
  backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);
  final profiles = _RecordingProfileRepository(backend);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      profileRepositoryProvider.overrideWithValue(profiles),
      profileOverviewRepositoryProvider.overrideWithValue(
        FakeProfileOverviewRepository(backend),
      ),
      homeRepositoryProvider.overrideWithValue(FakeHomeRepository(backend)),
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
  router.go(location);
  await tester.pumpAndSettle();
  return (router, profiles);
}

/// The location on top (pushed pages included).
String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('the bottom bar has 6 tabs that fit at 360 dp; Settings opens', (
    tester,
  ) async {
    final (router, _) = await _pump(tester, location: AppRoutes.learn);

    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(6));
    const labels = [
      'Home',
      'Learn',
      'Practice',
      'Insights',
      'Groups',
      'Settings',
    ];
    for (var i = 0; i < labels.length; i++) {
      final d = tester.widget<NavigationDestination>(destinations.at(i));
      expect(d.label, labels[i]);
      // Touch target >= 48 x 48.
      final size = tester.getSize(destinations.at(i));
      expect(size.width, greaterThanOrEqualTo(48), reason: labels[i]);
      expect(size.height, greaterThanOrEqualTo(48), reason: labels[i]);
      // The label never draws outside its slot. Tests use a block font
      // (every glyph 1 em wide), so real widths can't be measured here;
      // <= 8 characters is ~56 dp in Inter 12 sp, inside the 60 dp slot
      // that 6 tabs get at 360 dp ("Community" would be ~63 dp).
      expect(labels[i].length, lessThanOrEqualTo(8), reason: labels[i]);
      final text = find.descendant(
        of: destinations.at(i),
        matching: find.text(labels[i]),
      );
      final paragraph = tester.renderObject<RenderParagraph>(text.first);
      expect(
        paragraph.size.width,
        lessThanOrEqualTo(size.width),
        reason: labels[i],
      );
    }

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.settings);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      5,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings -> My profile keeps the bar, then Back', (
    tester,
  ) async {
    final (router, _) = await _pump(tester);

    expect(find.text('Nethmi Perera'), findsOneWidget);
    expect(find.text('Biological Science · A/L 2027'), findsOneWidget);
    await tester.tap(find.text('Nethmi Perera'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.settingsProfile);
    expect(find.byType(ProfileOverviewScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // The gear is gone: Settings is a tab now.
    expect(
      find.descendant(
        of: find.byType(ProfileOverviewScreen),
        matching: find.byIcon(Icons.settings_outlined),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.settings);
    expect(find.text('App settings'.toUpperCase()), findsOneWidget);
  });

  testWidgets('Study goals pre-fills, saves with PATCH and goes back', (
    tester,
  ) async {
    final (router, profiles) = await _pump(tester);

    expect(find.text('Target grade A · A/L 2027'), findsOneWidget);
    await tester.tap(find.text('Study goals'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.settingsEditProfile);
    expect(find.text('Set your goal'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // The saved answers were filled in and sent back unchanged.
    expect(profiles.patches, [
      {'exam_year': 2027, 'target_grade': 'A', 'confidence': 50},
    ]);
    expect(profiles.completes, 0); // onboarding didn't restart
    expect(_path(router), AppRoutes.settings);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('Study setup walks the 3 steps and saves each one', (
    tester,
  ) async {
    final (router, profiles) = await _pump(tester);

    await tester.tap(find.text('Study setup'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(profiles.patches, hasLength(3));
    expect(profiles.patches.first, {
      'stream': 'biological_science',
      'subject': 'biology',
    });
    expect(profiles.patches.last['preferred_time'], 'evening');
    expect(profiles.completes, 0);
    expect(_path(router), AppRoutes.settings);
  });

  testWidgets('Data & privacy opens inside the Settings tab', (tester) async {
    final (router, _) = await _pump(tester);

    final tile = find.text('Data & privacy');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.privacy);
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
