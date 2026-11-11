import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
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
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, s) => Scaffold(body: Text('AT ${s.uri.path}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
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
      'Dark mode',
      'Study reminders',
      'Evenings at 8:30 PM',
      'Community replies',
      'Study goals',
      'Data & privacy',
      'About AI in BrAInBox',
      'Help & feedback',
      'Log out',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.textContaining('BrAInBox v0.1.0 (fake)'), findsOneWidget);
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
}
