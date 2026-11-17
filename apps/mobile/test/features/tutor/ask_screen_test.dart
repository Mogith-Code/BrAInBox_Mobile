import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/tutor/presentation/ask_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget at(GoRouterState s) => Scaffold(body: Text('AT ${s.uri}'));
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.ask,
        builder: (_, s) => AskScreen(topicId: s.uri.queryParameters['topicId']),
      ),
      for (final path in [
        AppRoutes.home,
        AppRoutes.learn,
        AppRoutes.nextSteps,
        AppRoutes.quizSetup,
        AppRoutes.topic,
      ])
        GoRoute(path: path, builder: (_, s) => at(s)),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('says coming soon and has no chat input', (tester) async {
    await _pump(tester, AppRoutes.ask);

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('topicId'), findsNothing);

    await tester.tap(find.text('See my next steps'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.nextSteps}'), findsOneWidget);
  });

  testWidgets('with a topic, links back to it and to practice', (tester) async {
    await _pump(tester, AppRoutes.askPath(topicId: 't-1'));

    await tester.tap(find.text('Practise this topic'));
    await tester.pumpAndSettle();
    expect(
      find.text('AT ${AppRoutes.quizSetupPath(topicId: 't-1', mode: 'quick')}'),
      findsOneWidget,
    );
  });

  testWidgets('Back to the topic opens it when there is nothing to pop', (
    tester,
  ) async {
    await _pump(tester, AppRoutes.askPath(topicId: 't-1'));

    await tester.tap(find.text('Back to the topic'));
    await tester.pumpAndSettle();
    expect(find.text('AT ${AppRoutes.topicPath('t-1')}'), findsOneWidget);
  });
}
