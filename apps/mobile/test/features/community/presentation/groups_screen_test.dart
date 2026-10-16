import 'package:brainbox_mobile/features/community/data/community_repository.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/community/presentation/groups_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CommunityRepository {}

void main() {
  testWidgets('GroupsScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const CommunitySummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [communityRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: GroupsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
