import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../community_fixtures.dart';
import '../community_test_app.dart';

void main() {
  late MockCommunityRepository repository;

  setUpAll(registerCommunityFallbacks);
  setUp(() => repository = MockCommunityRepository());

  Future<void> open(WidgetTester tester, {bool isMine = false}) async {
    when(
      () => repository.fetchPost('p1'),
    ).thenAnswer((_) async => PostDetail.fromJson(detailJson(isMine: isMine)));
    await pumpCommunity(
      tester,
      location: AppRoutes.postDetailPath('p1'),
      repository: repository,
    );
  }

  testWidgets('AI answer first, then the accepted answer, then by score', (
    tester,
  ) async {
    await open(tester);

    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('AI answer'), lessThan(y('Accepted answer')));
    expect(y('Accepted answer'), lessThan(y('High score reply')));
    expect(y('High score reply'), lessThan(y('Low score reply')));

    expect(find.byType(AiBadge), findsOneWidget);
    expect(find.text('Helpful'), findsOneWidget);
    expect(find.text('Not helpful'), findsOneWidget);
    expect(find.text('Best answer'), findsOneWidget);
    expect(find.text('4 replies'), findsOneWidget);
    // Display names only.
    expect(find.textContaining('Nimali'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('Helpful is an upvote on the AI answer', (tester) async {
    when(
      () => repository.vote(replyId: 'r-ai', value: 1),
    ).thenAnswer((_) async => const VoteResult(myVote: 1, score: 3));

    await open(tester);
    await tester.tap(find.text('Helpful'));
    await tester.pumpAndSettle();

    verify(() => repository.vote(replyId: 'r-ai', value: 1)).called(1);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Helpful'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('upvoting the post updates the score', (tester) async {
    when(
      () => repository.vote(postId: 'p1', value: 1),
    ).thenAnswer((_) async => const VoteResult(myVote: 1, score: 4));

    await open(tester);
    await tester.tap(find.byTooltip('Upvote').first);
    await tester.pumpAndSettle();

    verify(() => repository.vote(postId: 'p1', value: 1)).called(1);
    expect(find.bySemanticsLabel('Score 4'), findsOneWidget);
  });

  testWidgets('my own reply cannot be voted on', (tester) async {
    await open(tester);

    // r-low is mine: its vote buttons are disabled.
    final lowCard = find.ancestor(
      of: find.text('Low score reply'),
      matching: find.byType(Card),
    );
    final votes = tester.widgetList<IconButton>(
      find.descendant(
        of: lowCard,
        matching: find.byWidgetPredicate(
          (w) =>
              w is IconButton &&
              (w.tooltip == 'Upvote' || w.tooltip == 'Downvote'),
        ),
      ),
    );
    expect(votes, hasLength(2));
    expect(votes.every((b) => b.onPressed == null), isTrue);
  });

  testWidgets('only the post author can mark the best answer', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Reply options').at(2)); // High score
    await tester.pumpAndSettle();
    expect(find.text('Mark as best answer'), findsNothing);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets('the author marks a reply as the best answer', (tester) async {
    when(
      () => repository.accept('p1', 'r-high'),
    ).thenAnswer((_) async => PostDetail.fromJson(detailJson(isMine: true)));

    await open(tester, isMine: true);
    await tester.tap(find.byTooltip('Reply options').at(2)); // High score
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as best answer'));
    await tester.pumpAndSettle();

    verify(() => repository.accept('p1', 'r-high')).called(1);
  });

  testWidgets('reporting a reply sends the chosen reason', (tester) async {
    when(
      () => repository.reportReply(
        'r-high',
        reason: any(named: 'reason'),
        details: any(named: 'details'),
      ),
    ).thenAnswer((_) async {});

    await open(tester);
    await tester.tap(find.byTooltip('Reply options').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrong information'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    verify(
      () => repository.reportReply(
        'r-high',
        reason: ReportReason.wrongInfo,
        details: '',
      ),
    ).called(1);
    expect(find.text('Thanks. A moderator will check it.'), findsOneWidget);
  });

  testWidgets('sending a reply adds it to the list', (tester) async {
    when(() => repository.createReply('p1', 'Great question')).thenAnswer(
      (_) async => Reply.fromJson(
        replyJson(id: 'r-new', body: 'Great question', isMine: true),
      ),
    );

    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'Great question');
    await tester.tap(find.byTooltip('Send reply'));
    await tester.pumpAndSettle();

    verify(() => repository.createReply('p1', 'Great question')).called(1);
    expect(find.text('Great question'), findsOneWidget);
    expect(find.text('5 replies'), findsOneWidget);
  });

  testWidgets('a missing post shows the error with Retry', (tester) async {
    when(() => repository.fetchPost('p1')).thenThrow(
      const ApiException(
        code: 'POST_NOT_FOUND',
        message: 'Post not found',
        statusCode: 404,
      ),
    );
    await pumpCommunity(
      tester,
      location: AppRoutes.postDetailPath('p1'),
      repository: repository,
    );

    expect(find.byType(ErrorBanner), findsOneWidget);
  });
}
