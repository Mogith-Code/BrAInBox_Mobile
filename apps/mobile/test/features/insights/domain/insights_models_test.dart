import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../insights_fixtures.dart';

void main() {
  group('TopicInsights.fromJson', () {
    final data = TopicInsights.fromJson(sampleInsightsJson());

    test('reads the overall result and keeps the server topic order', () {
      expect(data.attemptsAnalysed, 3);
      expect(data.minQuestionsPerTopic, 5);
      expect(data.overall.percent, 61.76);
      expect(data.overall.gradeLabel, 'Credit Pass');
      expect(data.topics.first.topic, 'Dihybrid crosses');
      expect(data.topics.map((t) => t.topic), [
        'Dihybrid crosses',
        'Photosynthesis',
        'Sex linkage',
        'General',
        'Gene technology',
        'Enzymes',
        'Cell structure',
      ]);
    });

    test('keeps null percent and grade (not attempted)', () {
      final cell = data.topicByName('Cell structure')!;
      expect(cell.percent, isNull);
      expect(cell.grade, isNull);
      expect(cell.gradeLabel, isNull);
      expect(cell.status, TopicStatus.notAttempted);

      final empty = TopicInsights.fromJson(emptyInsightsJson());
      expect(empty.overall.percent, isNull);
      expect(empty.isEmpty, isTrue);
    });

    test('a null topic_id uses the name as key and matches feedback', () {
      final general = data.topicByName('General')!;
      expect(general.topicId, isNull);
      expect(general.key, 'name:General');
      expect(general.unitName, 'Other');
      expect(data.topicByKey('name:General'), general);
      expect(
        data.feedbackFor(general)!.summary,
        'General questions are going fine.',
      );
    });

    test('feedback is matched by topic_id', () {
      final dihybrid = data.topicByName('Dihybrid crosses')!;
      final feedback = data.feedbackFor(dihybrid)!;
      expect(feedback.reviewQuestions, hasLength(2));
      expect(feedback.reviewQuestions[1].modelAnswer, isNull);
      expect(feedback.misconceptions.single.title, contains('Linked genes'));
    });

    test('an unknown status falls back to unknown', () {
      expect(data.topicByName('Gene technology')!.status, TopicStatus.unknown);
    });

    test('an unknown resource_type falls back to unknown', () {
      final resources = data.feedback.first.resources;
      expect(resources[0].resourceType, ResourceType.video);
      expect(resources[1].resourceType, ResourceType.unknown);
    });

    test('unknown values can be written back to JSON', () {
      expect(() => data.toJson(), returnsNormally);
    });

    test('missing lists default to empty', () {
      final minimal = TopicInsights.fromJson({
        'overall': {'correct': 0, 'attempted': 0},
      });
      expect(minimal.topics, isEmpty);
      expect(minimal.gradeBands, isEmpty);
      expect(minimal.note, isEmpty);
    });
  });

  group('helpers', () {
    final data = TopicInsights.fromJson(sampleInsightsJson());

    test('units appear in the order they first appear in topics', () {
      expect(data.unitsInOrder, [
        'Genetics',
        'Plant biology',
        'Other',
        'Cell biology',
      ]);
      expect(data.topicsInUnit('Genetics').map((t) => t.topic), [
        'Dihybrid crosses',
        'Sex linkage',
        'Gene technology',
      ]);
    });

    test('strongest is the last reliable topic, weakest the first weak', () {
      expect(data.strongestTopic!.topic, 'Enzymes');
      expect(data.weakestTopic!.topic, 'Dihybrid crosses');
    });

    test('status counts', () {
      expect(data.statusCounts[TopicStatus.veryWeak], 1);
      expect(data.statusCounts[TopicStatus.unknown], 1);
      expect(data.statusCounts[TopicStatus.good], isNull);
    });

    test('questionsNeeded never goes below zero', () {
      expect(data.topicByName('Sex linkage')!.questionsNeeded(5), 3);
      expect(data.topicByName('Dihybrid crosses')!.questionsNeeded(5), 0);
    });

    test('no strongest or weakest topic when there is no data', () {
      final empty = TopicInsights.fromJson(emptyInsightsJson());
      expect(empty.strongestTopic, isNull);
      expect(empty.weakestTopic, isNull);
    });
  });
}
