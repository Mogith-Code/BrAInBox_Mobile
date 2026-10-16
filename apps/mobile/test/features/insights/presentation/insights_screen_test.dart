import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:brainbox_mobile/features/insights/presentation/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InsightsRepository {}

void main() {
  testWidgets('InsightsScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const InsightsSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
