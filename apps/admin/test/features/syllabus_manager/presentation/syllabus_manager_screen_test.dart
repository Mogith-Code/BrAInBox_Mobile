import 'package:brainbox_admin/features/syllabus_manager/data/syllabus_manager_repository.dart';
import 'package:brainbox_admin/features/syllabus_manager/domain/syllabus_manager_models.dart';
import 'package:brainbox_admin/features/syllabus_manager/presentation/syllabus_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeSyllabusManagerRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeSyllabusManagerRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [syllabusManagerRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SyllabusManagerScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Opens Unit 6 and topic 6.2 and selects the outdated concept.
Future<void> _openBloodGroup(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Expand').at(5)); // 06 Genetics
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find
          .ancestor(
            of: find.text('6.2 Deviations from Mendel'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byTooltip('Expand'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Blood group (old syllabus)'));
  await tester.pumpAndSettle();
}

void main() {
  test('reads the backend admin syllabus JSON', () {
    final concept = AdminConcept.fromJson({
      'id': 'c1',
      'topic_id': 't1',
      'code': '6.2.4',
      'name': 'Blood group',
      'learning_outcome': 'Explains ABO',
      'order_index': 3,
      'is_outdated': true,
    });
    expect(concept.isOutdated, isTrue);
    expect(concept.learningOutcome, 'Explains ABO');
  });

  testWidgets('shows the tree and marks outdated nodes', (tester) async {
    await _pump(tester);

    expect(find.text('Syllabus manager'), findsOneWidget);
    expect(find.text('Biological Science'), findsOneWidget);
    expect(find.text('06 Genetics'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(2));

    await _openBloodGroup(tester);
    expect(
      find.text('Outdated syllabus'),
      findsNWidgets(2),
    ); // topic 6.3 + concept
    expect(
      find.text('Biology › 06 Genetics › 6.2 Deviations from Mendel'),
      findsOneWidget,
    );
    expect(find.textContaining('Explains inheritance of ABO'), findsOneWidget);
  });

  testWidgets('saving un-flags the concept', (tester) async {
    final repo = await _pump(tester);
    await _openBloodGroup(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Saved.'), findsOneWidget);
    final saved = (await repo.concepts('t6.2')).last;
    expect(saved.isOutdated, isFalse);
  });

  testWidgets('Add concept puts a new concept under the topic', (tester) async {
    final repo = await _pump(tester);
    await _openBloodGroup(tester);

    await tester.tap(find.text('Add concept'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first,
      'Polygenes',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Polygenes'), findsOneWidget);
    expect(
      (await repo.concepts('t6.2')).map((c) => c.name),
      contains('Polygenes'),
    );
  });
}
