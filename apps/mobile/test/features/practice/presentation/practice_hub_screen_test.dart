import 'package:brainbox_mobile/features/practice/data/practice_repository.dart';
import 'package:brainbox_mobile/features/practice/domain/practice_models.dart';
import 'package:brainbox_mobile/features/practice/presentation/practice_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements PracticeRepository {}

void main() {
  testWidgets('PracticeHubScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const PracticeSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [practiceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PracticeHubScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
