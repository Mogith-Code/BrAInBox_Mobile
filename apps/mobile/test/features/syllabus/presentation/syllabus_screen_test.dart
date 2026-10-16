import 'package:brainbox_mobile/features/syllabus/data/syllabus_repository.dart';
import 'package:brainbox_mobile/features/syllabus/domain/syllabus_models.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SyllabusRepository {}

void main() {
  testWidgets('SyllabusScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const SyllabusSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [syllabusRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SyllabusScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
