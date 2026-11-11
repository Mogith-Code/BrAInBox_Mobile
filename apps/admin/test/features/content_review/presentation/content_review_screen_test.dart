import 'package:brainbox_admin/features/content_review/data/content_review_repository.dart';
import 'package:brainbox_admin/features/content_review/domain/content_review_models.dart';
import 'package:brainbox_admin/features/content_review/presentation/content_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentReviewRepositoryProvider.overrideWithValue(
          FakeContentReviewRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ContentReviewScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('reads the content type from the backend', () {
    final item = ContentItem.fromJson({
      'id': 'x',
      'title': 'T',
      'type': 'short_note',
      'status': 'pending_review',
      'is_ai_generated': true,
    });
    expect(item.type, ContentType.shortNote);
    expect(item.isAiGenerated, isTrue);
  });

  testWidgets('lists items and previews the first one', (tester) async {
    await _pump(tester);

    expect(find.text('Content library'), findsOneWidget);
    expect(
      find.text('Notes, short notes & diagrams · 5 items'),
      findsOneWidget,
    );
    expect(
      find.text('Nephron structure & function'),
      findsNWidgets(2),
    ); // row + preview
    expect(
      find.text('Model: Gemini 2.5 Flash · notes/short.v2'),
      findsOneWidget,
    );
    expect(find.textContaining('not in NIE glossary'), findsOneWidget);
  });

  testWidgets('the Diagrams tab filters the table', (tester) async {
    await _pump(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Diagrams'));
    await tester.pumpAndSettle();

    expect(find.text('Meiosis stages'), findsWidgets);
    expect(find.text('Enzyme kinetics'), findsNothing);
  });

  testWidgets('Approve changes the status', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Approved. Students can see it now.'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);
  });
}
