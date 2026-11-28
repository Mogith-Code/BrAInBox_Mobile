import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../syllabus/learn_test_app.dart';

/// Pumps a few frames (the thinking card animates forever, so no
/// pumpAndSettle while it shows).
Future<void> _frames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The Notes tab opens on Government notes. These topics have no book, so
/// the empty state offers a button to AI notes.
Future<void> _showAiNotes(WidgetTester tester) async {
  final button = find.text('Open AI notes');
  if (button.evaluate().isEmpty) return;
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, String topicId) async {
  await _showAiNotes(tester);
  await tester.tap(find.text('Generate notes'));
  await tester.pumpAndSettle();
  expect(find.text('Generate'), findsOneWidget);
}

void main() {
  testWidgets('form: depth cards, toggles, note type', (tester) async {
    await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.topicPath('t-pedigree'),
    );
    await _showAiNotes(tester);
    expect(find.text('No notes yet'), findsOneWidget);
    await _openSheet(tester, 't-pedigree');

    expect(find.text('Pedigree analysis · Unit 6'), findsOneWidget);
    for (final d in NoteDepth.values) {
      expect(find.text(d.label), findsOneWidget);
      expect(find.text(d.readTime), findsOneWidget);
    }
    expect(find.text('Include examples'), findsOneWidget);
    expect(find.text('Include past-paper tips'), findsOneWidget);
    expect(find.text('Full notes'), findsOneWidget);
    expect(find.text('Short notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'generate: thinking, then closes, shows notes and "Notes ready"',
    (tester) async {
      final repo = fastMock();
      await pumpLearnApp(
        tester,
        repository: repo,
        initialLocation: AppRoutes.topicPath('t-pedigree'),
      );
      await _openSheet(tester, 't-pedigree');
      await tester.tap(find.text('Quick'));
      await tester.pump();

      await tester.tap(find.text('Generate'));
      await tester.pump();
      expect(find.text('BrAInBox is thinking'), findsOneWidget);

      await _frames(tester);
      await tester.pumpAndSettle();
      expect(find.text('BrAInBox is thinking'), findsNothing);
      expect(find.text('Notes ready'), findsOneWidget);
      expect(find.text('AI-generated'), findsOneWidget);
      expect(find.text('2 min read'), findsOneWidget);
    },
  );

  testWidgets('a failed job shows the error; Retry generates again', (
    tester,
  ) async {
    final repo = fastMock()..failNextGeneration = true;
    await pumpLearnApp(
      tester,
      repository: repo,
      initialLocation: AppRoutes.topicPath('t-pedigree'),
    );
    await _openSheet(tester, 't-pedigree');

    await tester.tap(find.text('Generate'));
    await _frames(tester);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't generate notes"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await _frames(tester);
    await tester.pumpAndSettle();
    expect(find.text('Notes ready'), findsOneWidget);
  });

  testWidgets('Short Notes tab generates short notes', (tester) async {
    await pumpLearnApp(
      tester,
      repository: fastMock(),
      initialLocation: AppRoutes.topicPath('t-mendelian'),
    );
    await tester.tap(find.widgetWithText(Tab, 'Short Notes'));
    await tester.pumpAndSettle();
    expect(find.text('No short notes yet'), findsOneWidget);

    await tester.tap(find.text('Generate short notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate'));
    await _frames(tester);
    await tester.pumpAndSettle();
    expect(find.text('Notes ready'), findsOneWidget);
    expect(find.text('Mendelian inheritance: key points'), findsOneWidget);
  });
}
