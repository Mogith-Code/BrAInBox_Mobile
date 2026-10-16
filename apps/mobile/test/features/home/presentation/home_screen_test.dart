import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/home/domain/home_models.dart';
import 'package:brainbox_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements HomeRepository {}

void main() {
  testWidgets('HomeScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const HomeSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
