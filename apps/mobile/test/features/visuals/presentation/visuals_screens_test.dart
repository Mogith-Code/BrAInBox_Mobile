import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/visuals/data/fake_visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/presentation/diagram_gallery_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/diagram_viewer_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/generate_visual_screen.dart';
import 'package:brainbox_mobile/features/visuals/presentation/widgets/visual_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A visual whose labels have x / y, so the markers are drawn on it.
const _placed = Visual(
  id: 'v-placed',
  title: 'Nephron structure',
  imageUrl: 'https://example.com/nephron.png',
  isAiGenerated: true,
  width: 400,
  height: 300,
  labels: [
    VisualLabel(
      number: 1,
      name: "Bowman's capsule",
      description: 'Cup-shaped end of the nephron.',
      x: 0.2,
      y: 0.2,
    ),
    VisualLabel(
      number: 2,
      name: 'PCT',
      description: 'Takes back all the glucose.',
      x: 0.6,
      y: 0.5,
    ),
  ],
);

class _Repo extends FakeVisualsRepository {
  _Repo() : super(step: Duration.zero);

  @override
  Future<Visual> visual(String visualId) async =>
      visualId == _placed.id ? _placed : super.visual(visualId);
}

Future<_Repo> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Repo();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.visuals,
        builder: (_, s) =>
            DiagramGalleryScreen(topicId: s.pathParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.diagramViewer,
        builder: (_, s) =>
            DiagramViewerScreen(visualId: s.pathParameters['visualId']!),
      ),
      GoRoute(
        path: AppRoutes.generateVisual,
        builder: (_, s) =>
            GenerateVisualScreen(topicId: s.uri.queryParameters['topicId']),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [visualsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('Diagrams gallery', () {
    testWidgets('shows the topic, filters and opens a diagram', (tester) async {
      await _pump(tester, AppRoutes.visualsPath('t-mendel'));

      expect(find.text('Mendelian inheritance'), findsOneWidget);
      expect(find.textContaining('Unit 6'), findsOneWidget);
      expect(find.text('Monohybrid cross'), findsOneWidget);
      expect(find.text('Nephron structure'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoicePill, 'Verified'));
      await tester.pumpAndSettle();
      expect(find.text('Nephron structure'), findsNothing); // AI-generated
      expect(find.text('Monohybrid cross'), findsOneWidget);

      await tester.tap(find.text('Monohybrid cross'));
      await tester.pumpAndSettle();
      expect(find.text('Report inaccuracy'), findsOneWidget);
    });

    testWidgets('the last card opens Generate a visual for the topic', (
      tester,
    ) async {
      await _pump(tester, AppRoutes.visualsPath('t-mendel'));
      await tester.tap(find.widgetWithText(ChoicePill, 'Verified'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate a new visual'));
      await tester.pumpAndSettle();
      expect(find.text('What do you want to see?'), findsOneWidget);
    });
  });

  group('Diagram viewer', () {
    testWidgets('tapping a number shows that part; Labels hides markers', (
      tester,
    ) async {
      await _pump(tester, AppRoutes.diagramViewerPath(_placed.id));

      expect(find.text('Cup-shaped end of the nephron.'), findsOneWidget);
      final marker2 = find.bySemanticsLabel('Label 2: PCT');
      expect(marker2, findsOneWidget);

      await tester.tap(marker2);
      await tester.pumpAndSettle();
      expect(find.text('Takes back all the glucose.'), findsOneWidget);

      await tester.tap(find.text('Labels'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Label 2: PCT'), findsNothing);
    });

    testWidgets('Report inaccuracy sends the reason', (tester) async {
      final repo = await _pump(tester, AppRoutes.diagramViewerPath(_placed.id));

      await tester.tap(find.text('Report inaccuracy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A label is wrong'));
      await tester.pump();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(repo.reports, isNotEmpty);
      expect(find.textContaining('A teacher will check'), findsOneWidget);
    });

    testWidgets('an unknown id shows an error with Retry', (tester) async {
      await _pump(tester, AppRoutes.diagramViewerPath('nope'));
      expect(find.byType(ErrorBanner), findsOneWidget);
    });
  });

  group('Generate a visual', () {
    testWidgets('needs a description, then opens the new visual', (
      tester,
    ) async {
      await _pump(tester, AppRoutes.generateVisualPath(topicId: 't-mendel'));

      AppButton generateButton() => tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Generate visual'),
      );
      expect(generateButton().onPressed, isNull);

      await tester.tap(find.text('Comparison'));
      await tester.pump();
      expect(find.text('Meiosis'), findsOneWidget); // comparison preview

      await tester.enterText(find.byType(TextField), 'mitosis vs meiosis');
      await tester.pump();
      expect(generateButton().onPressed, isNotNull);

      await tester.tap(find.text('Generate visual'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Mitosis vs meiosis'), findsOneWidget); // viewer title
      expect(find.text('Report inaccuracy'), findsOneWidget);
    });

    testWidgets('shows the error when the AI fails', (tester) async {
      await _pump(tester, AppRoutes.generateVisualPath());

      await tester.enterText(find.byType(TextField), 'this will fail');
      await tester.pump();
      await tester.tap(find.text('Generate visual'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.textContaining('could not draw'), findsOneWidget);
    });
  });
}
