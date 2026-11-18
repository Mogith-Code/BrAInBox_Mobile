import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/insights/data/mistakes_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/mistake_models.dart';
import 'package:brainbox_mobile/features/insights/domain/recurring_mistakes.dart';
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

  @override
  Future<RecurringMistakes> recurring() async => const RecurringMistakes();
}

/// The fake journal, with [recurringJson] (or [recurringError]) for
/// `GET /mistakes/recurring`.
class _WithRecurring extends FakeMistakesRepository {
  _WithRecurring({this.recurringJson, this.recurringError});

  final Map<String, dynamic>? recurringJson;
  final Object? recurringError;
  int calls = 0;

  @override
  Future<RecurringMistakes> recurring() async {
    calls++;
    if (recurringError != null) throw recurringError!;
    return RecurringMistakes.fromJson(recurringJson!);
  }
}

Map<String, dynamic> _recurring(String trend, {String? topicId = 't-5-4'}) => {
  'items': [
    {
      'misconception_id': 'mc1',
      'title': 'Confuses ADH & aldosterone',
      'description': null,
      'correction': 'ADH controls water; aldosterone controls sodium.',
      'count': 4,
      'previous_count': 1,
      'trend': trend,
      'last_at': '2026-11-16T10:00:00Z',
      'concept_id': 'c1',
      'concept': 'Hormonal control',
      'topic_id': topicId,
      'topic': 'Excretion & osmoregulation',
    },
  ],
  'window_days': 14,
  'min_count': 3,
};

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
        builder: (_, s) => Scaffold(body: Text('AT ${s.uri}')),
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
    // Nothing to practise: no "Practice my mistakes".
    expect(find.text('Practice my mistakes'), findsNothing);
  });

  testWidgets('Practice my mistakes opens a mistakes quiz', (tester) async {
    await _pump(tester, FakeMistakesRepository());

    await tester.tap(find.text('Practice my mistakes'));
    await tester.pumpAndSettle();
    expect(
      find.text('AT ${AppRoutes.quizSetupPath(mode: 'mistakes')}'),
      findsOneWidget,
    );
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

  group('Recurring mistakes', () {
    testWidgets('shows count, trend word and icon', (tester) async {
      await _pump(tester, _WithRecurring(recurringJson: _recurring('up')));

      expect(find.text('Recurring mistakes'), findsOneWidget);
      expect(find.text('Rising'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Trend: rising'), findsOneWidget);
      expect(
        find.text('4× in the last 14 days (1× the 14 days before)'),
        findsOneWidget,
      );
      expect(
        find.text('Excretion & osmoregulation · Hormonal control'),
        findsOneWidget,
      );
      // The journal's own cards are still below it.
      expect(find.text('Mark fixed'), findsNWidgets(2));
    });

    testWidgets('falling and steady trends', (tester) async {
      await _pump(tester, _WithRecurring(recurringJson: _recurring('down')));
      expect(find.text('Falling'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);

      await _pump(tester, _WithRecurring(recurringJson: _recurring('same')));
      expect(find.text('Steady'), findsOneWidget);
    });

    testWidgets('Practise topic opens quiz setup for that topic', (
      tester,
    ) async {
      await _pump(tester, _WithRecurring(recurringJson: _recurring('up')));

      await tester.tap(find.text('Practise topic'));
      await tester.pumpAndSettle();
      expect(
        find.text('AT ${AppRoutes.quizSetupPath(topicId: 't-5-4')}'),
        findsOneWidget,
      );
    });

    testWidgets('no topic means no Practise button', (tester) async {
      await _pump(
        tester,
        _WithRecurring(recurringJson: _recurring('up', topicId: null)),
      );
      expect(find.text('Practise topic'), findsNothing);
    });

    testWidgets('none recurring says so', (tester) async {
      await _pump(
        tester,
        _WithRecurring(
          recurringJson: {'items': [], 'window_days': 14, 'min_count': 3},
        ),
      );
      expect(
        find.text('No repeat mistakes in the last 14 days. Keep it up!'),
        findsOneWidget,
      );
    });

    testWidgets('an error shows Retry and keeps the journal', (tester) async {
      final repo = _WithRecurring(recurringError: Exception('down'));
      await _pump(tester, repo);

      expect(find.text("Couldn't load recurring mistakes."), findsOneWidget);
      expect(find.text('Mark fixed'), findsNWidgets(2));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
    });

    testWidgets('only on the To fix tab', (tester) async {
      await _pump(tester, _WithRecurring(recurringJson: _recurring('up')));
      await tester.tap(find.text('Mark fixed').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fixed'));
      await tester.pumpAndSettle();
      expect(find.text('Recurring mistakes'), findsNothing);
    });
  });
}
