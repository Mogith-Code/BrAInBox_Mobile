import 'package:brainbox_admin/features/syllabus_manager/data/syllabus_manager_repository.dart';
import 'package:brainbox_admin/features/syllabus_manager/domain/syllabus_manager_models.dart';
import 'package:brainbox_admin/features/syllabus_manager/presentation/syllabus_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SyllabusManagerRepository {}

void main() {
  testWidgets('SyllabusManagerScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const SyllabusManagerSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syllabusManagerRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: SyllabusManagerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
