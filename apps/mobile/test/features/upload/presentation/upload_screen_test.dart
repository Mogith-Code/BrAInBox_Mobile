import 'package:brainbox_mobile/features/upload/data/upload_repository.dart';
import 'package:brainbox_mobile/features/upload/domain/upload_models.dart';
import 'package:brainbox_mobile/features/upload/presentation/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements UploadRepository {}

void main() {
  testWidgets('UploadScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const UploadSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [uploadRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: UploadScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
