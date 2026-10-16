import 'package:brainbox_admin/features/mcq_mapping/data/mcq_mapping_repository.dart';
import 'package:brainbox_admin/features/mcq_mapping/domain/mcq_mapping_models.dart';
import 'package:brainbox_admin/features/mcq_mapping/presentation/mcq_mapping_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements McqMappingRepository {}

void main() {
  testWidgets('McqMappingScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const McqMappingSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mcqMappingRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: McqMappingScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
