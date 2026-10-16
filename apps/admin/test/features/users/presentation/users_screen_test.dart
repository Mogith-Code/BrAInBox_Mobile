import 'package:brainbox_admin/features/users/data/users_repository.dart';
import 'package:brainbox_admin/features/users/domain/users_models.dart';
import 'package:brainbox_admin/features/users/presentation/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements UsersRepository {}

void main() {
  testWidgets('UsersScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const UsersSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [usersRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: UsersScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
