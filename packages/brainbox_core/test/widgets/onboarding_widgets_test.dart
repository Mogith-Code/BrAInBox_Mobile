import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('OtpCodeField', () {
    testWidgets('typing fills the boxes and completes at 6 digits', (
      tester,
    ) async {
      String? completed;
      final changes = <String>[];
      await tester.pumpWidget(
        _wrap(
          OtpCodeField(
            onChanged: changes.add,
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('otp-input')), '4827');
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(completed, isNull);

      await tester.enterText(find.byKey(const ValueKey('otp-input')), '482715');
      await tester.pump();
      expect(completed, '482715');
      expect(changes.last, '482715');
    });

    testWidgets('pasting a formatted code keeps only the 6 digits', (
      tester,
    ) async {
      String? completed;
      await tester.pumpWidget(
        _wrap(OtpCodeField(onCompleted: (code) => completed = code)),
      );
      await tester.enterText(
        find.byKey(const ValueKey('otp-input')),
        '482-715',
      );
      await tester.pump();
      expect(completed, '482715');
    });
  });

  testWidgets('PasswordStrengthMeter shows the Figma text', (tester) async {
    await tester.pumpWidget(
      _wrap(const PasswordStrengthMeter(password: 'Mito2027')),
    );
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Add a symbol to make it stronger'), findsOneWidget);
  });

  testWidgets('DayChips toggles days', (tester) async {
    var selected = <String>{'mon'};
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => DayChips(
            selected: selected,
            onChanged: (next) => setState(() => selected = next),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tu'));
    await tester.pump();
    expect(selected, {'mon', 'tue'});
    await tester.tap(find.text('Mo'));
    await tester.pump();
    expect(selected, {'tue'});
  });

  testWidgets('ExamYearPicker moves with the arrows', (tester) async {
    var year = 2027;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => ExamYearPicker(
            years: const [2026, 2027, 2028],
            value: year,
            onChanged: (y) => setState(() => year = y),
          ),
        ),
      ),
    );
    expect(find.text('2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Later year'));
    await tester.pump();
    expect(year, 2028);
  });

  testWidgets('PillSelector selects one option', (tester) async {
    String? value = 'A';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => PillSelector<String>(
            options: const ['A', 'B', 'C'],
            value: value,
            labelOf: (o) => o,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(value, 'B');
  });

  testWidgets('every new widget renders without errors', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SingleChildScrollView(
          child: Column(
            children: [
              const StepProgressHeader(step: 1, total: 3),
              SelectableCard(
                selected: true,
                onTap: () {},
                child: const Text('Biological Science'),
              ),
              const ComingSoonChip(),
              LabeledSlider(
                value: 50,
                min: 0,
                max: 100,
                minLabel: 'Not at all',
                maxLabel: 'Very',
                onChanged: (_) {},
              ),
              const Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.edit_outlined,
                      value: '15',
                      label: 'quick MCQs',
                    ),
                  ),
                ],
              ),
              const AppChip(
                emoji: '🔥',
                label: '12-day streak',
                tone: AppChipTone.streak,
              ),
              const UnitMasteryRow(
                index: 6,
                title: 'Genetics',
                mastery: 0.26,
                status: MasteryStatus.needsWork,
              ),
              GoogleSignInButton(
                label: 'Sign up with Google',
                onPressed: () {},
              ),
              const IconTile(icon: Icons.shield_outlined),
              const OrDivider(),
              InlineLink(
                text: 'New to BrAInBox?',
                link: 'Create account',
                onTap: () {},
              ),
              const SkeletonBox(height: 20),
              const PhoneField(),
              const AiBadge(),
              const AiBadge(label: 'Adaptive', onDark: true),
              const AppLogo(variant: AppLogoVariant.wordmark, onDark: true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Step 1 of 3'), findsNothing); // it's a semantics label
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('12-day streak'), findsOneWidget);
    expect(find.text('26%'), findsOneWidget);
  });
}
