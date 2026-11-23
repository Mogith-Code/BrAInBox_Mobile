import 'package:brainbox_mobile/features/tutor/data/tutor_repository.dart';
import 'package:brainbox_mobile/features/tutor/presentation/ask_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTutor implements TutorRepository {
  _FakeTutor({this.fail = false});

  final bool fail;
  String? askedTopic;

  @override
  Future<TutorAnswer> ask(String question, {String? topicId}) async {
    askedTopic = topicId;
    if (fail) throw Exception('down');
    return const TutorAnswer(
      answer: 'Water moves towards the lower water potential.',
      grounded: true,
      sources: [TutorSource(title: 'Unit04 Plants', page: 12)],
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  TutorRepository repo, {
  String? topicId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tutorRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: AskScreen(topicId: topicId)),
    ),
  );
  await tester.pump();
}

Future<void> _ask(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'What is osmosis?');
  await tester.tap(find.byTooltip('Send'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the answer with its source, for the topic', (
    tester,
  ) async {
    final repo = _FakeTutor();
    await _pump(tester, repo, topicId: 't-1');

    await _ask(tester);

    expect(find.text('What is osmosis?'), findsOneWidget);
    expect(
      find.text('Water moves towards the lower water potential.'),
      findsOneWidget,
    );
    expect(find.text('Sources: Unit04 Plants, p. 12'), findsOneWidget);
    expect(repo.askedTopic, 't-1');
  });

  testWidgets('a failed request shows a friendly error', (tester) async {
    await _pump(tester, _FakeTutor(fail: true));

    await _ask(tester);

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });
}
