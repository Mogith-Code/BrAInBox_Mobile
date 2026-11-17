import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/insights/domain/unit_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';
import '../community_test_app.dart';

void main() {
  late MockCommunityRepository repository;

  final general = groupJson(
    id: 'g0',
    name: 'General',
    slug: 'general',
    isDefault: true,
    isMember: true,
    members: 120,
  );
  final unit6 = groupJson(
    id: 'g6',
    name: 'Genetics',
    slug: 'unit-6',
    unitId: 'u-6',
  );
  final unit2 = groupJson(
    id: 'g2',
    name: 'Cell biology',
    slug: 'unit-2',
    unitId: 'u-2',
  );

  setUp(() => repository = MockCommunityRepository());

  testWidgets('shows my groups and groups to join, weak units first', (
    tester,
  ) async {
    when(repository.fetchGroups).thenAnswer(
      (_) async => [
        for (final g in [general, unit6, unit2]) StudyGroup.fromJson(g),
      ],
    );

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
    );

    expect(find.text('My groups'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('120 members'), findsOneWidget);
    expect(find.text('Groups to join'), findsOneWidget);
    // Unit 2 (41 %, weak) comes before unit 6 (88 %), with a status chip.
    final cell = tester.getTopLeft(find.text('Cell biology'));
    final genetics = tester.getTopLeft(find.text('Genetics'));
    expect(cell.dy, lessThan(genetics.dy));
    expect(find.text('Weak'), findsOneWidget);
    expect(find.text('Join'), findsNWidgets(2));
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('Join calls the backend and moves the group', (tester) async {
    when(repository.fetchGroups).thenAnswer(
      (_) async => [StudyGroup.fromJson(general), StudyGroup.fromJson(unit2)],
    );
    when(() => repository.join('g2')).thenAnswer(
      (_) async => StudyGroup.fromJson({...unit2, 'is_member': true}),
    );

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
    );
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    verify(() => repository.join('g2')).called(1);
    expect(find.text('Groups to join'), findsNothing);
    expect(find.text('Leave'), findsNWidgets(2));
  });

  testWidgets('groups still show when unit mastery fails', (tester) async {
    when(repository.fetchGroups).thenAnswer(
      (_) async => [StudyGroup.fromJson(general), StudyGroup.fromJson(unit2)],
    );

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
      insights: fakeInsights(error: Exception('offline')),
    );

    expect(find.text('Cell biology'), findsOneWidget);
    expect(find.text('Weak'), findsNothing);
  });

  testWidgets('shows the error with Retry', (tester) async {
    when(
      repository.fetchGroups,
    ).thenThrow(const ApiException(code: 'network', message: 'offline'));

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
    );

    expect(find.byType(ErrorBanner), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a groups error while mastery is still loading reaches the '
      'error state (no uncaught error)', (tester) async {
    when(repository.fetchGroups).thenAnswer(
      (_) => Future<List<StudyGroup>>.delayed(
        const Duration(milliseconds: 10),
        () => throw const ApiException(code: 'network', message: 'offline'),
      ),
    );
    final slowInsights = MockInsightsRepository();
    when(slowInsights.fetchUnitInsights).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 50),
        () => UnitInsights.fromJson(unitsJson()),
      ),
    );

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
      insights: slowInsights,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    when(repository.fetchGroups).thenAnswer((_) async => []);

    await pumpCommunity(
      tester,
      location: AppRoutes.community,
      repository: repository,
    );

    expect(find.text('No study groups yet'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
