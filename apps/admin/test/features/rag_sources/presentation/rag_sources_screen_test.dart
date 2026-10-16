import 'package:brainbox_admin/features/rag_sources/data/rag_sources_repository.dart';
import 'package:brainbox_admin/features/rag_sources/domain/rag_sources_models.dart';
import 'package:brainbox_admin/features/rag_sources/presentation/rag_sources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements RagSourcesRepository {}

void main() {
  testWidgets('RagSourcesScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const RagSourcesSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ragSourcesRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: RagSourcesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
