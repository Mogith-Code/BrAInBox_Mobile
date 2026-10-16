import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/settings/data/settings_repository.dart';
import 'package:brainbox_mobile/features/settings/domain/settings_models.dart';
import 'package:brainbox_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SettingsRepository {}

void main() {
  testWidgets('SettingsScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const SettingsSummary(title: 'Test'));
    when(() => repository.appVersion()).thenAnswer((_) async => '1.2.3 (4)');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    // Settings > About shows the logo and the version.
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Version 1.2.3 (4)'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
