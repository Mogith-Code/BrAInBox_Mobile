import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/presentation/heatmap_screen.dart';
import 'package:brainbox_mobile/features/insights/presentation/widgets/heatmap_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../insights_fixtures.dart';
import '../insights_test_app.dart';

void main() {
  group('HeatmapScreen', () {
    testWidgets('shows one row per unit and one cell per topic', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(find.text('Mastery map'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.byType(HeatmapCell), findsNWidgets(7));
      // Percent only in the cells, as the backend sent it (rounded).
      expect(find.text('22'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      // Not attempted shows a dash, never 0.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      // Rows in syllabus order, labelled with the unit number from the
      // topic numbers; topics without a number go to "Other", last.
      final labels = [
        for (final view in tester.widgetList<MasteryMapRowView>(
          find.byType(MasteryMapRowView),
        ))
          view.row.label,
      ];
      expect(labels, [
        '1 Cell biology',
        '3 Plant biology',
        '6 Genetics',
        'Other',
      ]);
    });

    testWidgets('cells have a spoken label', (tester) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      expect(
        find.bySemanticsLabel('Dihybrid crosses, 22 percent, very weak'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Cell structure, not attempted, not attempted'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a cell opens the topic sheet and Open topic', (
      tester,
    ) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: sampleInsightsJson()),
      );

      await tester.tap(
        find.bySemanticsLabel('Dihybrid crosses, 22 percent, very weak'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TopicSheet), findsOneWidget);
      expect(find.text('Unit 6 Genetics'), findsOneWidget);
      expect(find.text('9 questions tried'), findsOneWidget);
      // The tapped cell is outlined while its sheet is open.
      final cell = tester.widget<HeatmapCell>(
        find.ancestor(of: find.text('22'), matching: find.byType(HeatmapCell)),
      );
      expect(cell.selected, isTrue);
      expect(find.text('Practice'), findsOneWidget);

      await tester.tap(find.text('Open topic'));
      await tester.pumpAndSettle();

      expect(find.text('Topic result'), findsOneWidget);
      expect(find.text('What this means'), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(json: emptyInsightsJson()),
      );

      expect(find.text('No results yet'), findsOneWidget);
    });

    testWidgets('shows the error with Retry', (tester) async {
      await pumpInsights(
        tester,
        const HeatmapScreen(),
        fakeRepository(error: const InsightsServerError('Server error')),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
