import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/insights/data/mistakes_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/mistake_models.dart';
import 'package:brainbox_mobile/features/insights/presentation/mistake_journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Empty implements MistakesRepository {
  @override
  Future<List<MistakeEntry>> mistakes(MistakeTab tab) async => const [];

  @override
  Future<void> setResolved(String id, {required bool resolved}) async {}
}

Future<void> _pump(WidgetTester tester, MistakesRepository repo) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.mistakeJournal,
    routes: [
      GoRoute(
        path: AppRoutes.mistakeJournal,
        builder: (_, _) => const MistakeJournalScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizSetup,
        builder: (_, s) => Scaffold(body: Text('AT ${s.uri.path}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mistakesRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test("reads the backend's MistakeOut", () {
    final m = MistakeEntry.fromJson({
      'id': 'm',
      'question_id': null,
      'question': null,
      'your_answer': null,
      'correct_answer': null,
      'explanation': null,
      'mistake_type': 'conceptual',
      'misconception': {
        'id': 'x',
        'title': 'Confuses ADH',
        'description': null,
      },
      'correction': null,
      'topic_id': null,
      'topic': 'Excretion',
      'topic_number': '5.4',
      'unit_id': null,
      'unit_number': 5,
      'unit': 'Animal form',
      'source': 'quiz',
      'is_resolved': false,
      'resolved_at': null,
      'created_at': '2026-11-01T10:00:00Z',
    });
    expect(m.question, isNull); // the question was deleted
    expect(m.misconception?.title, 'Confuses ADH');
  });

  testWidgets('no mistakes shows the F5 empty state', (tester) async {
    await _pump(tester, _Empty());

    expect(find.text('No mistakes yet — nice!'), findsOneWidget);
    await tester.tap(find.text('Take a quick quiz'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.quizSetup}'), findsOneWidget);
  });

  testWidgets('Mark fixed moves a mistake to the Fixed tab', (tester) async {
    await _pump(tester, FakeMistakesRepository());

    expect(
      find.text('Likely misconception: ', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Confuses ADH & aldosterone', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mark fixed'), findsNWidgets(2));

    await tester.tap(find.text('Mark fixed').first);
    await tester.pumpAndSettle();
    expect(find.text('Mark fixed'), findsOneWidget);
    expect(find.text('Nice! Marked as fixed.'), findsOneWidget);

    await tester.tap(find.text('Fixed'));
    await tester.pumpAndSettle();
    expect(find.text('Not fixed yet'), findsOneWidget);
  });
}
