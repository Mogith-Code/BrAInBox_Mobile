import 'package:brainbox_mobile/features/splash/data/splash_repository.dart';
import 'package:brainbox_mobile/features/splash/domain/splash_models.dart';
import 'package:brainbox_mobile/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SplashRepository {}

void main() {
  testWidgets('SplashScreen shows data from the repository', (tester) async {
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

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
