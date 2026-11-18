import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/community/application/community_controller.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';
import '../community_test_app.dart';

void main() {
  late MockCommunityRepository repository;

  setUp(() {
    repository = MockCommunityRepository();
    when(() => repository.fetchGroup('g6')).thenAnswer(
      (_) async => StudyGroup.fromJson(
        groupJson(
          id: 'g6',
          name: 'Genetics',
          slug: 'unit-6',
          unitId: 'u-6',
          isMember: true,
        ),
      ),
    );
    when(
      () => repository.suggestTopic(
        title: any(named: 'title'),
        body: any(named: 'body'),
        groupId: any(named: 'groupId'),
      ),
    ).thenAnswer(
      (_) async => const TopicSuggestion(
        topicId: 't-6-1',
        topic: 'Mendelian genetics',
        unitNumber: 6,
        confidence: 0.8,
      ),
    );
  });

  Future<void> open(WidgetTester tester) => pumpCommunity(
    tester,
    location: AppRoutes.createPostPath('g6'),
    repository: repository,
  );

  testWidgets('suggests a topic 800 ms after typing stops, with AiBadge', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Posting in Genetics'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Why 9:');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, 'Why 9:3:3:1');
    // Not yet: the student is still typing.
    await tester.pump(const Duration(milliseconds: 500));
    verifyNever(
      () => repository.suggestTopic(
        title: any(named: 'title'),
        body: any(named: 'body'),
        groupId: any(named: 'groupId'),
      ),
    );

    await tester.pump(CreatePostController.debounce);
    await tester.pumpAndSettle();

    // One request, for the final text only.
    verify(
      () => repository.suggestTopic(
        title: 'Why 9:3:3:1',
        body: '',
        groupId: 'g6',
      ),
    ).called(1);
    expect(find.text('Mendelian genetics'), findsOneWidget);
    expect(find.byType(AiBadge), findsOneWidget);
  });

  testWidgets('the suggested tag can be removed', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Why 9:3:3:1');
    await tester.pump(CreatePostController.debounce);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove topic'));
    await tester.pumpAndSettle();

    expect(find.text('Mendelian genetics'), findsNothing);
    expect(find.byType(AiBadge), findsNothing);
  });

  testWidgets('a flagged post says it is waiting for an admin', (tester) async {
    when(
      () => repository.createPost(
        'g6',
        title: any(named: 'title'),
        body: any(named: 'body'),
        isQuestion: any(named: 'isQuestion'),
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => Post.fromJson(postJson(id: 'p9', status: 'flagged')),
    );

    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Is this allowed?');
    await tester.enterText(find.byType(TextField).at(1), 'Some text');
    await tester.pump(CreatePostController.debounce);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for an admin'), findsOneWidget);
    verify(
      () => repository.createPost(
        'g6',
        title: 'Is this allowed?',
        body: 'Some text',
        isQuestion: true,
        topicId: 't-6-1',
      ),
    ).called(1);
  });

  testWidgets('an empty title is caught before sending', (tester) async {
    await open(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Write a title (3+ characters).'), findsOneWidget);
    expect(find.text('Write your post.'), findsOneWidget);
  });

  testWidgets('a send error is shown', (tester) async {
    when(
      () => repository.createPost(
        'g6',
        title: any(named: 'title'),
        body: any(named: 'body'),
        isQuestion: any(named: 'isQuestion'),
        topicId: any(named: 'topicId'),
      ),
    ).thenThrow(
      const ApiException(
        code: 'NOT_A_MEMBER',
        message: 'Join the group to post in it',
        statusCode: 403,
      ),
    );

    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Hello group');
    await tester.enterText(find.byType(TextField).at(1), 'Text');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Join the group to post in it'), findsOneWidget);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });
}
