import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/community/application/community_controller.dart';
import 'package:brainbox_mobile/features/community/data/community_repository.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/insights/domain/unit_insights.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';

class _MockApi extends Mock implements ApiClient {}

void main() {
  late _MockApi api;
  late CommunityRepository repository;

  setUp(() {
    api = _MockApi();
    repository = CommunityRepository(api);
  });

  test('GET /groups parses the groups', () async {
    when(() => api.get<List<dynamic>>('/groups')).thenAnswer(
      (_) async => [
        groupJson(id: 'g0', name: 'General', slug: 'general', isDefault: true),
        groupJson(id: 'g6', name: 'Genetics', slug: 'unit-6', unitId: 'u-6'),
      ],
    );

    final groups = await repository.fetchGroups();

    expect(groups.map((g) => g.name), ['General', 'Genetics']);
    expect(groups.last.unitNumber, 6);
    expect(groups.first.unitNumber, isNull);
  });

  test('the feed sends sort, page and size', () async {
    when(
      () => api.get<Map<String, dynamic>>(any(), query: any(named: 'query')),
    ).thenAnswer((_) async => pageJson([postJson(id: 'p1')], pages: 3));

    final page = await repository.fetchPosts('g6', sort: 'top', page: 2);

    expect(page.items.single.topic, 'Mendelian genetics');
    expect(page.hasMore, isTrue); // page 1 of 3
    verify(
      () => api.get<Map<String, dynamic>>(
        '/groups/g6/posts',
        query: {'sort': 'top', 'page': 2, 'size': 20},
      ),
    ).called(1);
  });

  test(
    'create post sends is_question and leaves out a missing topic',
    () async {
      when(
        () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => postJson(id: 'p9', status: 'flagged'));

      final post = await repository.createPost(
        'g6',
        title: 'Help',
        body: 'Body',
        isQuestion: false,
      );

      expect(post.moderationStatus, ModerationStatus.flagged);
      verify(
        () => api.post<Map<String, dynamic>>(
          '/groups/g6/posts',
          data: {'title': 'Help', 'body': 'Body', 'is_question': false},
        ),
      ).called(1);
    },
  );

  test('a vote targets exactly one post or reply', () async {
    when(
      () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => {'my_vote': -1, 'score': 4});

    final result = await repository.vote(replyId: 'r1', value: -1);

    expect(result.score, 4);
    verify(
      () => api.post<Map<String, dynamic>>(
        '/votes',
        data: {'reply_id': 'r1', 'value': -1},
      ),
    ).called(1);
  });

  test('a report sends the reason and trimmed details', () async {
    when(
      () => api.post<Object?>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => null);

    await repository.reportReply(
      'r1',
      reason: ReportReason.wrongInfo,
      details: '  wrong ratio  ',
    );

    verify(
      () => api.post<Object?>(
        '/replies/r1/report',
        data: {'reason': 'wrong_info', 'details': 'wrong ratio'},
      ),
    ).called(1);
  });

  test('suggest-topic sends the draft and the group', () async {
    when(
      () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => {
        'topic_id': 't-6-1',
        'topic': 'Mendelian genetics',
        'unit_number': 6,
        'confidence': 0.82,
        'ai_generated': true,
      },
    );

    final suggestion = await repository.suggestTopic(
      title: 'Ratio',
      body: '',
      groupId: 'g6',
    );

    expect(suggestion.topic, 'Mendelian genetics');
    verify(
      () => api.post<Map<String, dynamic>>(
        '/posts/suggest-topic',
        data: {'title': 'Ratio', 'body': '', 'group_id': 'g6'},
      ),
    ).called(1);
  });

  test('unit topics use the u6 code and the topic uuid', () async {
    when(() => api.get<Map<String, dynamic>>('/units/u6/topics')).thenAnswer(
      (_) async => {
        'topics': [
          {
            'id': 'bio-6.1',
            'uuid': 'uuid-61',
            'code': '6.1',
            'title': 'Mendel',
          },
        ],
      },
    );

    final topics = await repository.fetchUnitTopics(6);

    expect(topics.single.id, 'uuid-61');
    expect(topics.single.code, '6.1');
  });

  test('the post page orders AI answer, accepted answer, then by score', () {
    final detail = PostDetail.fromJson(detailJson());

    expect(detail.orderedReplies.map((r) => r.id), [
      'r-ai',
      'r-accepted',
      'r-high',
      'r-low',
    ]);
    // An AI answer has no author; nobody's email is ever in the model.
    expect(detail.orderedReplies.first.author, isNull);
  });

  test('groups: weak units first, then not assessed, then General', () {
    final groups = [
      StudyGroup.fromJson(
        groupJson(id: 'g0', name: 'General', slug: 'general'),
      ),
      StudyGroup.fromJson(
        groupJson(id: 'g6', name: 'U6', slug: 'unit-6', unitId: 'u-6'),
      ),
      StudyGroup.fromJson(
        groupJson(id: 'g3', name: 'U3', slug: 'unit-3', unitId: 'u-3'),
      ),
      StudyGroup.fromJson(
        groupJson(id: 'g2', name: 'U2', slug: 'unit-2', unitId: 'u-2'),
      ),
    ];
    final mastery = {
      for (final u in UnitInsights.fromJson(unitsJson()).units) u.unitId: u,
    };

    expect(weakUnitsFirst(groups, mastery).map((g) => g.id), [
      'g2', // 41
      'g6', // 88
      'g3', // not assessed
      'g0', // no unit
    ]);
    // Without mastery data the backend's order is kept.
    expect(weakUnitsFirst(groups, const {}).map((g) => g.id), [
      'g0',
      'g6',
      'g3',
      'g2',
    ]);
  });
}
