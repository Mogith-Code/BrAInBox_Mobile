import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/community/application/community_controller.dart';
import 'package:brainbox_mobile/features/community/data/community_repository.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';
import '../community_test_app.dart';

PostPage _page(
  List<Map<String, dynamic>> posts, {
  int page = 1,
  int pages = 1,
}) => PostPage.fromJson(pageJson(posts, page: page, pages: pages));

void main() {
  late MockCommunityRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockCommunityRepository();
    container = ProviderContainer(
      overrides: [
        communityRepositoryProvider.overrideWithValue(repository),
        insightsRepositoryProvider.overrideWithValue(fakeInsights()),
      ],
    );
    addTearDown(container.dispose);
  });

  group('feed', () {
    test(
      'Unanswered keeps posts without replies and reads more pages',
      () async {
        when(
          () => repository.fetchPosts(
            'g6',
            sort: 'new',
            page: 1,
            size: any(named: 'size'),
          ),
        ).thenAnswer(
          (_) async => _page([postJson(id: 'p1', replyCount: 2)], pages: 2),
        );
        when(
          () => repository.fetchPosts(
            'g6',
            sort: 'new',
            page: 2,
            size: any(named: 'size'),
          ),
        ).thenAnswer(
          (_) async => _page([postJson(id: 'p2')], page: 2, pages: 2),
        );

        final args = (groupId: 'g6', sort: FeedSort.unanswered);
        final sub = container.listen(feedProvider(args), (_, _) {});
        addTearDown(sub.close);
        final feed = await container.read(feedProvider(args).future);

        // Page 1 had nothing unanswered, so page 2 was read too.
        expect(feed.visible.map((p) => p.id), ['p2']);
        expect(feed.posts, hasLength(2));
        expect(feed.hasMore, isFalse);
      },
    );

    test('loadMore appends the next page without duplicates', () async {
      when(
        () => repository.fetchPosts(
          'g6',
          sort: 'top',
          page: 1,
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _page([postJson(id: 'p1')], pages: 2));
      when(
        () => repository.fetchPosts(
          'g6',
          sort: 'top',
          page: 2,
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async =>
            _page([postJson(id: 'p1'), postJson(id: 'p2')], page: 2, pages: 2),
      );

      final args = (groupId: 'g6', sort: FeedSort.top);
      final sub = container.listen(feedProvider(args), (_, _) {});
      addTearDown(sub.close);
      await container.read(feedProvider(args).future);
      await container.read(feedProvider(args).notifier).loadMore();

      final feed = container.read(feedProvider(args)).value!;
      expect(feed.posts.map((p) => p.id), ['p1', 'p2']);
      expect(feed.hasMore, isFalse);
    });
  });

  group('post detail', () {
    test('a vote shows at once and takes the server score', () async {
      when(
        () => repository.fetchPost('p1'),
      ).thenAnswer((_) async => PostDetail.fromJson(detailJson()));
      when(
        () => repository.vote(postId: 'p1', value: 1),
      ).thenAnswer((_) async => const VoteResult(myVote: 1, score: 10));

      final sub = container.listen(postDetailProvider('p1'), (_, _) {});
      addTearDown(sub.close);
      await container.read(postDetailProvider('p1').future);
      final error = await container
          .read(postDetailProvider('p1').notifier)
          .vote(value: 1);

      expect(error, isNull);
      final post = container.read(postDetailProvider('p1')).value!.post;
      expect(post.score, 10);
      expect(post.myVote, 1);
    });

    test('a refused vote is undone and explained', () async {
      when(
        () => repository.fetchPost('p1'),
      ).thenAnswer((_) async => PostDetail.fromJson(detailJson()));
      when(() => repository.vote(replyId: 'r-high', value: -1)).thenThrow(
        const ApiException(
          code: 'NOT_A_MEMBER',
          message: 'Join the group to vote',
          statusCode: 403,
        ),
      );

      final sub = container.listen(postDetailProvider('p1'), (_, _) {});
      addTearDown(sub.close);
      final before = await container.read(postDetailProvider('p1').future);
      final reply = before.replies.firstWhere((r) => r.id == 'r-high');
      final error = await container
          .read(postDetailProvider('p1').notifier)
          .vote(reply: reply, value: -1);

      expect(error, 'Join the group to vote');
      final after = container
          .read(postDetailProvider('p1'))
          .value!
          .replies
          .firstWhere((r) => r.id == 'r-high');
      expect(after.score, 5);
      expect(after.myVote, 0);
    });

    test('ALREADY_REPORTED gets a message about this content', () {
      expect(
        communityErrorMessage(
          const ApiException(code: 'ALREADY_REPORTED', message: 'x'),
        ),
        'You already reported this. An admin will check it soon.',
      );
    });
  });

  test('joining moves a group to My groups', () async {
    final general = groupJson(id: 'g0', name: 'General', isMember: true);
    final unit2 = groupJson(
      id: 'g2',
      name: 'Unit 2',
      slug: 'unit-2',
      unitId: 'u-2',
    );
    when(repository.fetchGroups).thenAnswer(
      (_) async => [StudyGroup.fromJson(general), StudyGroup.fromJson(unit2)],
    );
    when(() => repository.join('g2')).thenAnswer(
      (_) async => StudyGroup.fromJson({...unit2, 'is_member': true}),
    );

    final sub = container.listen(groupsProvider, (_, _) {});
    addTearDown(sub.close);
    final before = await container.read(groupsProvider.future);
    expect(before.toJoin.map((g) => g.id), ['g2']);
    expect(before.isWeak(before.toJoin.single), isTrue);

    final error = await container
        .read(groupsProvider.notifier)
        .setMember(before.toJoin.single, join: true);

    expect(error, isNull);
    final after = container.read(groupsProvider).value!;
    // Weak unit 2 first, General (no unit) last.
    expect(after.myGroups.map((g) => g.id), ['g2', 'g0']);
    expect(after.toJoin, isEmpty);
  });
}
