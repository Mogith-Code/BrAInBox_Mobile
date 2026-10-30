import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/syllabus/data/syllabus_repository.dart';
import 'package:brainbox_mobile/features/syllabus/domain/syllabus_models.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SyllabusRepository {}

const _units = [
  UnitProgress(
    id: 'unit-1',
    order: 1,
    title: 'Introduction to Biology',
    topicCount: 4,
    mastery: 0.88,
    status: UnitStatus.mastered,
  ),
  UnitProgress(
    id: 'unit-6',
    order: 6,
    title: 'Genetics',
    topicCount: 9,
    mastery: 42, // 0-100 is accepted too
    status: UnitStatus.weak,
    topicTitles: ['Dihybrid crosses'],
  ),
];

Future<void> _pump(WidgetTester tester, SyllabusRepository repository) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.learn,
    routes: [
      GoRoute(path: AppRoutes.learn, builder: (_, _) => const SyllabusScreen()),
      for (final path in [AppRoutes.unitDetail, AppRoutes.notesLibrary])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(body: Text('AT ${state.uri.path}')),
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // Like main.dart: show errors instead of retrying in the background.
      retry: (_, _) => null,
      overrides: [syllabusRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.fetchUnits()).thenAnswer((_) async => _units);
  });

  test('filterUnits matches unit titles and topic titles', () {
    expect(filterUnits(_units, ''), _units);
    expect(filterUnits(_units, 'BIOLOGY').single.id, 'unit-1');
    expect(filterUnits(_units, 'dihybrid').single.id, 'unit-6');
    expect(filterUnits(_units, 'zzz'), isEmpty);
  });

  testWidgets('shows every unit with status, topics and mastery', (
    tester,
  ) async {
    await _pump(tester, repository);

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('UNIT 1'), findsOneWidget);
    expect(find.text('Introduction to Biology'), findsOneWidget);
    expect(find.text('Mastered'), findsOneWidget);
    expect(find.text('4 topics'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Genetics'), findsOneWidget);
    expect(find.text('Weak'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    verify(() => repository.fetchUnits()).called(1);
  });

  testWidgets('search filters the list and shows an empty state', (
    tester,
  ) async {
    await _pump(tester, repository);

    await tester.enterText(find.byType(TextField), 'dihybrid');
    await tester.pump();
    expect(find.text('Genetics'), findsOneWidget);
    expect(find.text('Introduction to Biology'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No matching units'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();
    expect(find.text('Introduction to Biology'), findsOneWidget);
  });

  testWidgets('tapping a unit opens its detail page', (tester) async {
    await _pump(tester, repository);

    await tester.tap(find.text('Genetics'));
    await tester.pumpAndSettle();

    expect(
      find.text('AT ${AppRoutes.unitDetailPath('unit-6')}'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error with Retry when loading fails', (tester) async {
    when(() => repository.fetchUnits()).thenThrow(Exception('offline'));
    await _pump(tester, repository);

    expect(find.text('Retry'), findsOneWidget);
  });
}
