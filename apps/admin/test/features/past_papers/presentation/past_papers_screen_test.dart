import 'package:brainbox_admin/features/past_papers/data/past_papers_repository.dart';
import 'package:brainbox_admin/features/past_papers/domain/past_papers_models.dart';
import 'package:brainbox_admin/features/past_papers/presentation/past_papers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements PastPapersRepository {}

void main() {
  testWidgets('PastPapersScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const PastPapersSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [pastPapersRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: PastPapersScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
