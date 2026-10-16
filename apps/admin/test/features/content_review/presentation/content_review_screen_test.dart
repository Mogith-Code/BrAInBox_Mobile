import 'package:brainbox_admin/features/content_review/data/content_review_repository.dart';
import 'package:brainbox_admin/features/content_review/domain/content_review_models.dart';
import 'package:brainbox_admin/features/content_review/presentation/content_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ContentReviewRepository {}

void main() {
  testWidgets('ContentReviewScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const ContentReviewSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentReviewRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: ContentReviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
