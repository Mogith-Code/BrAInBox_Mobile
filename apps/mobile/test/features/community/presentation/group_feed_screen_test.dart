import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';
import '../community_test_app.dart';

void main() {
  late MockCommunityRepository repository;

  void stubGroup({required bool member}) {
    when(() => repository.fetchGroup('g6')).thenAnswer(
      (_) async => StudyGroup.fromJson(
        groupJson(
          id: 'g6',
          name: 'Genetics',
          slug: 'unit-6',
          unitId: 'u-6',
          isMember: member,
        ),
      ),
    );
  }

  void stubFeed(String sort, List<Map<String, dynamic>> posts) {
    when(
      () => repository.fetchPosts(
        'g6',
        sort: sort,
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => PostPage.fromJson(pageJson(posts)));
  }

  setUp(() => repository = MockCommunityRepository());

  testWidgets('shows posts with topic tag, score and reply count', (
    tester,
  ) async {
    stubGroup(member: true);
    stubFeed('new', [
      postJson(id: 'p1', score: 7, replyCount: 3, acceptedReplyId: 'r1'),
    ]);

    await pumpCommunity(
      tester,
      location: AppRoutes.groupFeedPath('g6'),
      repository: repository,
    );

    expect(find.text('Genetics'), findsOneWidget); // app bar
    expect(find.text('Why is the F2 ratio 9:3:3:1?'), findsOneWidget);
    expect(find.text('Mendelian genetics'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    // The card is one button, so TalkBack reads its parts in one label.
    expect(find.bySemanticsLabel(RegExp(r'Score 7')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'3 replies')), findsOneWidget);
    // Members get the New post button.
    expect(find.text('New post'), findsOneWidget);
  });

  testWidgets('Unanswered shows only posts without replies', (tester) async {
    stubGroup(member: true);
    stubFeed('new', [
      postJson(id: 'p1', title: 'Answered one', replyCount: 2),
      postJson(id: 'p2', title: 'Nobody replied'),
    ]);

    await pumpCommunity(
      tester,
      location: AppRoutes.groupFeedPath('g6'),
      repository: repository,
    );
    await tester.tap(find.text('Unanswered'));
    await tester.pumpAndSettle();

    expect(find.text('Nobody replied'), findsOneWidget);
    expect(find.text('Answered one'), findsNothing);
  });

  testWidgets('Top asks the backend for sort=top', (tester) async {
    stubGroup(member: true);
    stubFeed('new', [postJson(id: 'p1', title: 'Newest')]);
    stubFeed('top', [postJson(id: 'p2', title: 'Most votes')]);

    await pumpCommunity(
      tester,
      location: AppRoutes.groupFeedPath('g6'),
      repository: repository,
    );
    await tester.tap(find.text('Top'));
    await tester.pumpAndSettle();

    expect(find.text('Most votes'), findsOneWidget);
  });

  testWidgets('non-members see Join instead of New post', (tester) async {
    stubGroup(member: false);
    stubFeed('new', []);

    await pumpCommunity(
      tester,
      location: AppRoutes.groupFeedPath('g6'),
      repository: repository,
    );

    expect(find.text('New post'), findsNothing);
    expect(find.text('Join this group to post and reply.'), findsOneWidget);
    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('a feed error shows Retry', (tester) async {
    stubGroup(member: true);
    when(
      () => repository.fetchPosts(
        'g6',
        sort: any(named: 'sort'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenThrow(const ApiException(code: 'network', message: 'offline'));

    await pumpCommunity(
      tester,
      location: AppRoutes.groupFeedPath('g6'),
      repository: repository,
    );

    expect(find.byType(ErrorBanner), findsOneWidget);
  });
}
