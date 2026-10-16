import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/domain/visuals_models.dart';
import 'package:brainbox_mobile/features/visuals/presentation/diagram_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements VisualsRepository {}

void main() {
  testWidgets('DiagramGalleryScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const VisualsSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [visualsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: DiagramGalleryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
