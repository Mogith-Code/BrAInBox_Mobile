import 'package:brainbox_mobile/features/syllabus/domain/syllabus_models.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/widgets/learn_widgets.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/widgets/topic_row.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/widgets/unit_card.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

MasteryRing _ring(WidgetTester tester) =>
    tester.widget<MasteryRing>(find.byType(MasteryRing));

void main() {
  group('MasteryChip', () {
    final expected = {
      MasteryLevel.weak: ('Weak', Icons.warning_amber_rounded),
      MasteryLevel.improving: ('Improving', Icons.trending_up),
      MasteryLevel.strong: ('Strong', Icons.check),
      MasteryLevel.mastered: ('Mastered', Icons.eco),
    };
    for (final MapEntry(key: level, value: (label, icon)) in expected.entries) {
      testWidgets('$label has its label and icon', (tester) async {
        await _pump(tester, MasteryChip(level: level));
        expect(find.text(label), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.bySemanticsLabel('Mastery: $label'), findsOneWidget);
      });
    }
  });

  group('UnitCard', () {
    testWidgets('shows caption, title, chip, topics and ring %', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        UnitCard(
          unit: const UnitProgress(
            id: 'unit-6',
            order: 6,
            title: 'Genetics',
            topicCount: 9,
            masteryPercent: 42,
            masteryLevel: MasteryLevel.weak,
          ),
          onTap: () => taps++,
        ),
      );
      expect(find.text('UNIT 6'), findsOneWidget);
      expect(find.text('Genetics'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('9 topics'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      await tester.tap(find.byType(UnitCard));
      expect(taps, 1);
    });

    testWidgets('ring colour: >75 green, >45 teal, else amber', (tester) async {
      for (final (percent, color) in [
        (88.0, AppColors.success),
        (60.0, AppColors.secondary),
        (45.0, AppColors.warning),
      ]) {
        await _pump(
          tester,
          UnitCard(
            unit: UnitProgress(id: 'u', title: 'U', masteryPercent: percent),
            onTap: () {},
          ),
        );
        expect(_ring(tester).color, color, reason: '$percent%');
      }
    });

    testWidgets('long titles do not overflow at 360px', (tester) async {
      await _pump(
        tester,
        UnitCard(
          unit: const UnitProgress(
            id: 'u',
            order: 7,
            title: 'Molecular Biology & Recombinant DNA Technology and more',
            topicCount: 9,
            masteryLevel: MasteryLevel.improving,
          ),
          onTap: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TopicRow', () {
    testWidgets('not started: number, slate pill, no bar, no dot', (
      tester,
    ) async {
      await _pump(
        tester,
        TopicRow(
          topic: const TopicProgress(id: 't', title: 'Sex linkage', order: 6),
          onTap: () {},
        ),
      );
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Not started'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('weak-dot')), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('in progress + weak: bar and orange dot', (tester) async {
      await _pump(
        tester,
        TopicRow(
          topic: const TopicProgress(
            id: 't',
            title: 'Monohybrid & dihybrid crosses',
            order: 2,
            status: TopicStatus.inProgress,
            progressPercent: 25,
            isWeak: true,
          ),
          onTap: () {},
        ),
      );
      expect(find.text('In progress'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.25);
      expect(find.byKey(const ValueKey('weak-dot')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('flagged as weak')), findsOneWidget);
    });

    testWidgets('mastered: green check instead of the number', (tester) async {
      await _pump(
        tester,
        TopicRow(
          topic: const TopicProgress(
            id: 't',
            title: 'Pedigree analysis',
            order: 7,
            status: TopicStatus.mastered,
          ),
          onTap: () {},
        ),
      );
      expect(find.text('7'), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
    });
  });
}
