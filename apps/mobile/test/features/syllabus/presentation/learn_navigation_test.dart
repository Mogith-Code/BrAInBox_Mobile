import 'dart:typed_data';

import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../learn_test_app.dart';

/// Some states animate forever (indeterminate bars); pump a fixed time.
Future<void> _frames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Learn -> unit -> topic -> tabs, and back', (tester) async {
    final repo = fastMock();
    await pumpLearnApp(tester, repository: repo);

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Introduction to Biology'), findsOneWidget);
    expect(find.text('My uploaded notes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Genetics'), 200);
    await tester.tap(find.text('Genetics'));
    await tester.pumpAndSettle();
    expect(find.text('UNIT 6'), findsOneWidget);
    expect(find.text('9 topics · 2 mastered · 3 weak'), findsOneWidget);
    expect(
      find.text('Orange dot = weak topic, flagged from your answers'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mendelian inheritance'));
    await tester.pumpAndSettle();
    expect(find.text('Biology › Unit 6 › Mendelian inheritance'), findsOneWidget);
    expect(find.text('Improving'), findsOneWidget);
    for (final tab in ['Notes', 'Short Notes', 'Diagrams', 'Videos', 'Practice']) {
      expect(find.widgetWithText(Tab, tab), findsOneWidget, reason: tab);
    }
    // Opening the topic is reported.
    expect(repo.progressLog.first.$2, ProgressEvent.opened);

    // Notes render every block type.
    expect(find.text('Unit 6 · 6.1 Mendelian inheritance'), findsOneWidget);
    expect(find.text('AI-generated'), findsOneWidget);
    expect(find.text('6 min read'), findsOneWidget);
    expect(find.text('DEFINITION'), findsOneWidget);
    expect(find.text('Genotype and phenotype'), findsOneWidget);
    expect(find.text("Mendel's first law: law of segregation"), findsOneWidget);
    expect(find.text('TT (tall)'), findsOneWidget); // table
    await tester.scrollUntilVisible(find.text('PAST-PAPER TIP'), 300);
    expect(find.text('9 yellow round (Y_R_)'), findsOneWidget); // bullets
    await tester.pumpAndSettle();
    // Scrolled to the end: a completed read was sent.
    expect(
      repo.progressLog.where((e) => e.$2 == ProgressEvent.read && e.$3),
      isNotEmpty,
    );
    expect(find.text('Ask BrAInBox'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Diagrams'));
    await tester.pumpAndSettle();
    expect(find.text('Monohybrid cross Punnett square'), findsOneWidget);
    expect(find.text('Ask BrAInBox'), findsNothing);

    await tester.tap(find.widgetWithText(Tab, 'Videos'));
    await tester.pumpAndSettle();
    expect(find.text('Mendelian inheritance explained'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Practice'));
    await tester.pumpAndSettle();
    expect(find.text('48'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    await tester.tap(find.text('Quick 10 MCQs'));
    await tester.pumpAndSettle();
    expect(
      find.text('AT ${AppRoutes.quizSetupPath(topicId: 't-mendelian', mode: 'quick')}'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Back to the unit, then Learn.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('UNIT 6'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsOneWidget);
  });

  testWidgets('search filters units, finds topics, shows the sprout empty state', (
    tester,
  ) async {
    await pumpLearnApp(tester, repository: fastMock());

    await tester.enterText(find.byType(TextField), 'genet');
    await tester.pump(SyllabusScreen.searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('Genetics'), findsOneWidget);
    expect(find.text('Introduction to Biology'), findsNothing);
    expect(find.text('My uploaded notes'), findsNothing);

    await tester.enterText(find.byType(TextField), 'pedigree');
    await tester.pump(SyllabusScreen.searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Pedigree analysis'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(SyllabusScreen.searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('No units match "zzz"'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Introduction to Biology'), findsOneWidget);
  });

  testWidgets('bookmark toggle shows in the Library; removing it there works', (
    tester,
  ) async {
    final router = await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.topicPath('t-mendelian'),
    );
    await tester.tap(find.byTooltip('Save to My library'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to My library'), findsOneWidget);

    router.go(AppRoutes.notesLibrary);
    await tester.pumpAndSettle();
    expect(find.text('Mendelian inheritance'), findsOneWidget);
    expect(find.text('Monohybrid & dihybrid crosses'), findsOneWidget); // seeded

    await tester.drag(find.text('Mendelian inheritance'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Mendelian inheritance'), findsNothing);

    router.go(AppRoutes.topicPath('t-mendelian'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Save to My library'), findsOneWidget);
  });

  testWidgets('upload a PDF -> processing -> summary -> save to short notes', (
    tester,
  ) async {
    final router = await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.learn,
      picker: ({required camera}) async =>
          PickedUploadFile(name: 'Lesson 4.pdf', bytes: Uint8List(8)),
    );
    await tester.tap(find.text('My uploaded notes'));
    await tester.pumpAndSettle();
    expect(find.text('Genetics tuition notes.pdf'), findsOneWidget);

    await tester.tap(find.text('Upload notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 4.pdf'), findsOneWidget);
    await tester.tap(find.text('Upload and summarise'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Uploading'), findsOneWidget);

    await _frames(tester, 40);
    expect(find.text('Processing'), findsNothing);
    expect(find.text('Ready'), findsNWidgets(2));

    await tester.tap(find.text('Lesson 4.pdf'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'Summary'), findsOneWidget);
    expect(find.textContaining("Mendel's two laws"), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Key points'));
    await tester.pumpAndSettle();
    expect(find.textContaining('law of segregation'), findsOneWidget);

    await tester.tap(find.text('Save to short notes'));
    await tester.pump();
    expect(find.text('Saved to your short notes'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Saved to short notes'), findsOneWidget);

    router.go(AppRoutes.notesLibrary);
    await tester.pumpAndSettle();
    expect(find.text('Saved short notes'), findsOneWidget);
    expect(find.text('Lesson 4.pdf'), findsOneWidget);
  });

  testWidgets('Undo keeps the upload out of the short notes', (tester) async {
    final repo = fastMock();
    await pumpLearnApp(
      tester,
      repository: repo,
      initialLocation: AppRoutes.uploadDetailPath('up-1'),
    );
    await tester.tap(find.text('Save to short notes'));
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    final bookmarks = await repo.fetchBookmarks();
    expect(bookmarks.where((b) => b.kind == BookmarkKind.shortNote), isEmpty);
  });

  testWidgets('a failed load shows the error card with Retry', (tester) async {
    await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.unitDetailPath('nope'),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('dark mode renders without overflow', (tester) async {
    await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.unitDetailPath('unit-6'),
      themeMode: ThemeMode.dark,
    );
    expect(find.text('Genetics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
