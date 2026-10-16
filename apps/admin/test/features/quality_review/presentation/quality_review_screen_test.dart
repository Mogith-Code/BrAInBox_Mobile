import 'package:brainbox_admin/features/quality_review/data/quality_review_repository.dart';
import 'package:brainbox_admin/features/quality_review/domain/quality_review_models.dart';
import 'package:brainbox_admin/features/quality_review/presentation/quality_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements QualityReviewRepository {}

void main() {
  testWidgets('QualityReviewScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const QualityReviewSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qualityReviewRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: QualityReviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
