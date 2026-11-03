import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/syllabus_screen.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/topic_screen.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/unit_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// B2 -> B3 -> B4 with the real screens and the repository's sample data.
Future<void> _pump(
  WidgetTester tester, {
  String initialLocation = AppRoutes.learn,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.learn, builder: (_, _) => const SyllabusScreen()),
      GoRoute(
        path: AppRoutes.unitDetail,
        builder: (_, state) =>
            UnitDetailScreen(unitId: state.pathParameters['unitId']!),
      ),
      GoRoute(
        path: AppRoutes.unitTopic,
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.topic,
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.ask,
        builder: (_, state) => Scaffold(body: Text('AT ${state.uri}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Learn -> unit -> topic', (tester) async {
    await _pump(tester);

    // B2 -> B3
    await tester.tap(find.text('Genetics'));
    await tester.pumpAndSettle();
    expect(find.text('UNIT 6'), findsOneWidget);
    expect(find.text('9 topics · 2 mastered · 3 weak'), findsOneWidget);
    expect(
      find.text('Orange dot = weak topic, flagged from your answers'),
      findsOneWidget,
    );
    expect(find.text('In progress'), findsWidgets);

    // B3 -> B4
    await tester.tap(find.text('Mendelian inheritance'));
    await tester.pumpAndSettle();
    expect(
      find.text('Biology › Unit 6 › Mendelian inheritance'),
      findsOneWidget,
    );
    expect(find.text('Improving'), findsOneWidget);
    for (final tab in ['Notes', 'Short Notes', 'Diagrams', 'Videos']) {
      expect(find.widgetWithText(Tab, tab), findsOneWidget, reason: tab);
    }

    // Back to B3, then B2.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('UNIT 6'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsOneWidget);
  });

  testWidgets('bookmark toggles and shows a snackbar', (tester) async {
    await _pump(
      tester,
      initialLocation: AppRoutes.unitTopicPath('unit-6', 't-mendelian'),
    );

    await tester.tap(find.byTooltip('Save to My library'));
    await tester.pump();
    expect(find.text('Saved to My library'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from My library'));
    await tester.pump();
    expect(find.text('Removed from My library'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('Ask BrAInBox shows on Notes and Diagrams only', (tester) async {
    await _pump(tester, initialLocation: AppRoutes.topicPath('t-dihybrid'));
    expect(find.text('Biology › Unit 6 › Dihybrid crosses'), findsOneWidget);

    expect(find.text('Ask BrAInBox'), findsOneWidget); // Notes
    await tester.tap(find.widgetWithText(Tab, 'Short Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Ask BrAInBox'), findsNothing);
    await tester.tap(find.widgetWithText(Tab, 'Diagrams'));
    await tester.pumpAndSettle();
    expect(find.text('Ask BrAInBox'), findsOneWidget);

    await tester.tap(find.text('Ask BrAInBox'));
    await tester.pumpAndSettle();
    expect(
      find.text('AT ${AppRoutes.askPath(topicId: 't-dihybrid')}'),
      findsOneWidget,
    );
  });

  testWidgets('an unknown unit shows an error with Retry', (tester) async {
    await _pump(tester, initialLocation: AppRoutes.unitDetailPath('nope'));

    expect(find.text('Retry'), findsOneWidget);
  });
}
