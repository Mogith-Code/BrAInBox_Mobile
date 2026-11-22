import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/profile/data/fake_profile_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_overview_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:brainbox_mobile/features/settings/data/settings_repository.dart';
import 'package:brainbox_mobile/features/settings/domain/settings_models.dart';
import 'package:brainbox_mobile/features/settings/presentation/privacy_screen.dart';
import 'package:brainbox_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingSaves extends FakeSettingsRepository {
  @override
  Future<NotificationSettings> saveNotifications(NotificationSettings value) =>
      throw const ApiException(code: 'network', message: 'offline');
}

/// The backend has no `/settings` endpoint yet (FastAPI's 404).
class _MissingEndpoint extends FakeSettingsRepository {
  @override
  Future<NotificationSettings> notifications() => throw const ApiException(
    code: 'http_404',
    message: 'Not Found',
    statusCode: 404,
  );
}

Future<SettingsRepository> _pump(
  WidgetTester tester, {
  String location = AppRoutes.settings,
  SettingsRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = repo ?? FakeSettingsRepository();
  final backend = FakeBackend(latency: Duration.zero);
  backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const PrivacyScreen(),
      ),
      for (final path in [
        AppRoutes.settingsProfile,
        AppRoutes.settingsEditProfile,
      ])
        GoRoute(
          path: path,
          builder: (_, s) => Scaffold(body: Text('AT ${s.uri}')),
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(backend),
        ),
        profileOverviewRepositoryProvider.overrideWithValue(
          FakeProfileOverviewRepository(backend),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  test('friendlyTime turns 24 h into AM / PM', () {
    expect(friendlyTime('20:30'), '8:30 PM');
    expect(friendlyTime('07:05'), '7:05 AM');
    expect(friendlyTime('00:00'), '12:00 AM');
    expect(friendlyTime('12:15'), '12:15 PM');
  });

  testWidgets('shows every section and the version', (tester) async {
    await _pump(tester);

    for (final text in [
      'Nethmi Perera',
      'Biological Science · A/L 2027',
      'PROFILE',
      'Edit profile',
      'Study goals',
      'Target grade A · A/L 2027',
      'Availability',
      '5 days a week · 2 h a day · Evening',
      'APP SETTINGS',
      'Dark mode',
      'Study reminders',
      'Every day at 8:30 PM',
      'Reminder time',
      'Community replies',
      'TRUST & SUPPORT',
      'Data & privacy',
      'About AI in BrAInBox',
      'Help & feedback',
      'Log out',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.textContaining('BrAInBox v0.1.0 (fake)'), findsOneWidget);
  });

  testWidgets('a 404 shows a friendly error with Retry, not a blank page', (
    tester,
  ) async {
    await _pump(tester, repo: _MissingEndpoint());

    expect(
      find.text("This isn't available yet. Please try again later."),
      findsOneWidget,
    );
    expect(find.text('Not Found'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    // The rest of Settings still works.
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Study goals'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('links open My profile and the edit sections', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Nethmi Perera'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.settingsProfile}'), findsOneWidget);
  });

  testWidgets('Availability opens edit mode at that section', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Availability'));
    await tester.pumpAndSettle();
    expect(
      find.text('AT ${AppRoutes.settingsEditProfilePath('availability')}'),
      findsOneWidget,
    );
  });

  testWidgets('a switch saves, and goes back if saving fails', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('Community replies'));
    await tester.pumpAndSettle();
    expect((await repo.notifications()).communityReplies, isFalse);

    await _pump(tester, repo: _FailingSaves());
    await tester.tap(find.text('Study reminders'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save that. Try again."), findsOneWidget);
    final reminders = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Study reminders'),
    );
    expect(reminders.value, isTrue); // rolled back
  });

  testWidgets('Data & privacy: required switch is locked, others save', (
    tester,
  ) async {
    final repo = await _pump(tester, location: AppRoutes.privacy);

    expect(find.text('Your data helps you, not advertisers.'), findsOneWidget);
    final required = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Personalised recommendations'),
    );
    expect(required.onChanged, isNull);

    await tester.tap(find.text('Share anonymised data for education research'));
    await tester.pumpAndSettle();
    expect((await repo.privacy()).shareResearch, isTrue);
  });

  testWidgets('delete dialog needs DELETE and closes without errors', (
    tester,
  ) async {
    await _pump(tester, location: AppRoutes.privacy);
    final tile = find.text('Delete my account');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete forever'),
    );
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    // Pump through the closing animation, while the TextField is still built.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Delete forever'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
