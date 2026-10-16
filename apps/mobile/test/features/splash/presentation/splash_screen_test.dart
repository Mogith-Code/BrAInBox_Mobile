import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/splash/data/splash_repository.dart';
import 'package:brainbox_mobile/features/splash/domain/splash_models.dart';
import 'package:brainbox_mobile/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SplashRepository {}

void main() {
  testWidgets('SplashScreen shows the logo, then Get started', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const SplashSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [splashRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
