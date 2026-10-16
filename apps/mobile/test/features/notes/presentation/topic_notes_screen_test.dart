import 'package:brainbox_mobile/features/notes/data/notes_repository.dart';
import 'package:brainbox_mobile/features/notes/domain/notes_models.dart';
import 'package:brainbox_mobile/features/notes/presentation/topic_notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotesRepository {}

void main() {
  testWidgets('TopicNotesScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const NotesSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notesRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: TopicNotesScreen(topicId: 'demo')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
