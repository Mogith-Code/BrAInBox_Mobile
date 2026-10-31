import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/presentation/topic_insight_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../insights_fixtures.dart';
import '../insights_test_app.dart';

void main() {
  group('TopicInsightScreen', () {
    testWidgets('shows the result, feedback and every section', (tester) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 't-dihybrid'),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(find.text('Dihybrid crosses'), findsOneWidget);
      expect(find.text('6.2 · Genetics'), findsOneWidget);
      expect(find.text('Very weak'), findsOneWidget);
      expect(find.text('2 correct of 9 attempted'), findsOneWidget);
      expect(find.text('1 unanswered'), findsOneWidget);
      expect(find.text('You are mixing up the 9:3:3:1 ratio.'), findsOneWidget);
      expect(find.text('Questions to review'), findsOneWidget);
      expect(find.text('Common misconceptions'), findsOneWidget);
      expect(find.text('Resources'), findsOneWidget);
      // Unknown resource type falls back to a generic link.
      expect(find.text('Link · example.org'), findsOneWidget);
    });

    testWidgets('model answer expands only when there is one', (tester) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 't-dihybrid'),
        fakeRepository(json: sampleInsightsJson()),
      );

      // Two questions, only one has a model answer.
      expect(find.text('Show model answer'), findsOneWidget);
      expect(find.text('9:3:3:1 in the F2 generation.'), findsNothing);

      await tester.tap(find.text('Show model answer'));
      await tester.pumpAndSettle();

      expect(find.text('9:3:3:1 in the F2 generation.'), findsOneWidget);
      expect(find.text('Hide model answer'), findsOneWidget);
    });

    testWidgets('hides empty sections (General group, null topic id)', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 'name:General'),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(find.text('General questions are going fine.'), findsOneWidget);
      expect(find.text('What to revise next'), findsNothing);
      expect(find.text('Questions to review'), findsNothing);
      expect(find.text('Common misconceptions'), findsNothing);
      expect(find.text('Resources'), findsNothing);
    });

    testWidgets('a topic without enough data shows how many are needed', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 't-sex'),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(find.text('Not enough data'), findsOneWidget);
      expect(find.text('Needs 3 more questions'), findsOneWidget);
    });

    testWidgets('an unknown topic shows a message', (tester) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 'missing'),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(find.text("This topic isn't in your results"), findsOneWidget);
    });

    testWidgets('shows the error with Retry', (tester) async {
      await pumpInsights(
        tester,
        const TopicInsightScreen(topicKey: 't-dihybrid'),
        fakeRepository(error: const InsightsServerError('Server error')),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
    });
  });
}
