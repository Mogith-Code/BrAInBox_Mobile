import 'package:brainbox_admin/features/question_bank/data/question_bank_repository.dart';
import 'package:brainbox_admin/features/question_bank/domain/question_bank_models.dart';
import 'package:brainbox_admin/features/question_bank/presentation/question_bank_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements QuestionBankRepository {}

void main() {
  testWidgets('QuestionBankScreen shows data from the repository', (
    tester,
  ) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const QuestionBankSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: QuestionBankScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
