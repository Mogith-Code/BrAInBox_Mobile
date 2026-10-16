import 'package:brainbox_admin/features/moderation/data/moderation_repository.dart';
import 'package:brainbox_admin/features/moderation/domain/moderation_models.dart';
import 'package:brainbox_admin/features/moderation/presentation/moderation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ModerationRepository {}

void main() {
  testWidgets('ModerationScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const ModerationSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [moderationRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ModerationScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
