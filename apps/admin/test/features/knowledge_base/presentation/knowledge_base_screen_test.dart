import 'package:brainbox_admin/features/knowledge_base/data/knowledge_base_repository.dart';
import 'package:brainbox_admin/features/knowledge_base/domain/knowledge_base_models.dart';
import 'package:brainbox_admin/features/knowledge_base/presentation/knowledge_base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements KnowledgeBaseRepository {}

void main() {
  testWidgets('KnowledgeBaseScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const KnowledgeBaseSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          knowledgeBaseRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: KnowledgeBaseScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
