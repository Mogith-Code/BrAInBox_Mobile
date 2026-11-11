import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/visuals/application/visuals_controller.dart';
import 'package:brainbox_mobile/features/visuals/data/fake_visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/recent_visuals_store.dart';
import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/presentation/diagram_viewer_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/generate_visual_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/my_visuals_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/widgets/visualise_anything_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Students can generate visuals about anything, from anywhere (Home,
/// My visuals), not only from a topic.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppRoutes.generateVisualPath', () {
    test('adds only the parts that are given', () {
      expect(AppRoutes.generateVisualPath(), '/visuals/generate');
      expect(
        AppRoutes.generateVisualPath(topicId: 't1'),
        '/visuals/generate?topicId=t1',
      );
      final uri = Uri.parse(
        AppRoutes.generateVisualPath(prompt: 'Krebs cycle & ATP'),
      );
      expect(uri.path, '/visuals/generate');
      expect(uri.queryParameters, {'prompt': 'Krebs cycle & ATP'});
      expect(AppRoutes.generateVisualPath(prompt: '  '), '/visuals/generate');
      expect(
        AppRoutes.learnVisualNewPath(topicId: 't1'),
        '/learn/visual/new?topicId=t1',
      );
    });
  });

  group('RecentVisualsStore', () {
    test('keeps the newest first, once, and at most 20', () async {
      final store = RecentVisualsStore();
      for (var i = 0; i < 25; i++) {
        await store.add('v$i');
      }
      await store.add('v20'); // again: moves to the front, no duplicate

      final ids = await store.ids();
      expect(ids.length, RecentVisualsStore.max);
      expect(ids.first, 'v20');
      expect(ids.where((id) => id == 'v20').length, 1);
      expect(ids, isNot(contains('v0'))); // oldest dropped

      await store.remove(['v20', 'v24']);
      expect(await store.ids(), isNot(contains('v20')));
    });
  });

  test('My visuals forgets ids the backend no longer has', () async {
    SharedPreferences.setMockInitialValues({
      'recent_visual_ids': ['v-nephron', 'gone-1', 'v-dna-gene'],
    });
    final c = ProviderContainer(
      overrides: [
        visualsRepositoryProvider.overrideWithValue(
          FakeVisualsRepository(step: Duration.zero),
        ),
      ],
    );
    addTearDown(c.dispose);

    final visuals = await c.read(myVisualsControllerProvider.future);

    expect(visuals.map((v) => v.id), ['v-nephron', 'v-dna-gene']);
    expect(await RecentVisualsStore().ids(), ['v-nephron', 'v-dna-gene']);
  });

  test('a generated visual without a topic is remembered', () async {
    final c = ProviderContainer(
      overrides: [
        visualsRepositoryProvider.overrideWithValue(
          FakeVisualsRepository(step: Duration.zero),
        ),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(generateVisualControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await c
        .read(generateVisualControllerProvider.notifier)
        .generate(prompt: 'Blood flow through the heart'); // no topic

    final id = sub.read().visual!.id;
    expect(await RecentVisualsStore().ids(), [id]);
    final mine = await c.read(myVisualsControllerProvider.future);
    expect(mine.single.id, id);
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(body: home),
          ),
          GoRoute(
            path: AppRoutes.myVisuals,
            builder: (_, _) => const MyVisualsScreen(),
          ),
          GoRoute(
            path: AppRoutes.generateVisual,
            builder: (_, s) => GenerateVisualScreen(
              topicId: s.uri.queryParameters['topicId'],
              initialPrompt: s.uri.queryParameters['prompt'],
            ),
          ),
          GoRoute(
            path: AppRoutes.diagramViewer,
            builder: (_, s) =>
                DiagramViewerScreen(visualId: s.pathParameters['visualId']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visualsRepositoryProvider.overrideWithValue(
              FakeVisualsRepository(step: Duration.zero),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an idea chip opens the generator with the idea filled in', (
      tester,
    ) async {
      await pump(tester, const VisualiseAnythingCard());

      expect(find.text('Visualise anything'), findsOneWidget);
      await tester.tap(find.text(visualIdeas.first));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, visualIdeas.first);
      expect(find.textContaining('Any Biology idea works'), findsOneWidget);
      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Generate visual'),
      );
      expect(button.onPressed, isNotNull); // ready to go
    });

    testWidgets('the card button opens My visuals (empty at first)', (
      tester,
    ) async {
      await pump(tester, const VisualiseAnythingCard());

      await tester.tap(find.text('Draw something'));
      await tester.pumpAndSettle();

      expect(find.text('My visuals'), findsOneWidget);
      expect(find.text('No visuals yet'), findsOneWidget);
    });

    testWidgets('My visuals lists what was made, newest first', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_visual_ids': ['v-dihybrid', 'v-monohybrid'],
      });
      await pump(tester, const MyVisualsScreen());

      expect(find.text('Recent on this phone'), findsOneWidget);
      expect(find.text('Dihybrid cross 9:3:3:1'), findsOneWidget);
      expect(find.text('Monohybrid cross'), findsOneWidget);

      await tester.tap(find.text('Monohybrid cross'));
      await tester.pumpAndSettle();
      expect(find.text('Report inaccuracy'), findsOneWidget); // the viewer
    });
  });
}
