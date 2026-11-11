import 'package:brainbox_admin/features/moderation/data/moderation_repository.dart';
import 'package:brainbox_admin/features/moderation/domain/moderation_models.dart';
import 'package:brainbox_admin/features/moderation/presentation/moderation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeModerationRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeModerationRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [moderationRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: ModerationScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test("reads today's visual reports from the backend", () {
    final item = ModerationItem.fromJson({
      'id': 'r1',
      'visual_id': 'v1',
      'reason': 'wrong_label',
      'status': 'pending',
      'target_type': 'visual',
      'reported_by': 'u1',
      'visual_title': 'Nephron',
      'created_at': '2026-11-01T10:00:00Z',
    });
    expect(item.targetType, ReportTarget.visual);
    expect(item.visualTitle, 'Nephron');
    expect(item.reportCount, 1);
  });

  testWidgets('shows the queue with AI flags and the groups', (tester) async {
    await _pump(tester);

    expect(find.text('Community moderation'), findsOneWidget);
    expect(find.text('4 reported · 6 study groups'), findsOneWidget);
    expect(find.textContaining('leaked 2026 papers'), findsOneWidget);
    expect(find.text('AI flag: Spam / external link · 96%'), findsOneWidget);
    expect(find.text('3 student reports'), findsOneWidget);
    expect(find.text('Exam stress & tips'), findsOneWidget);
    expect(find.text('No moderator'), findsOneWidget);
  });

  testWidgets('Remove takes the report out of the queue', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('leaked 2026 papers'), findsNothing);
    expect(find.text('Removed.'), findsOneWidget);
  });

  testWidgets('New group adds it to the list', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unit 7 · Molecular');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 7 · Molecular'), findsOneWidget);
  });
}
