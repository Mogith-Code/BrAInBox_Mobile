import 'package:brainbox_mobile/features/practice/domain/diagnostic_models.dart';
import 'package:brainbox_mobile/features/practice/presentation/diagnostic_result_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads units_not_checked from the API', () {
    final result = DiagnosticResult.fromJson({
      'attempt_id': 'a1',
      'units_not_checked': [
        {'unit_code': 'U10', 'unit_title': 'Applied Biology'},
      ],
    });

    expect(result.unitsNotChecked.single.unitLabel, 'Unit 10');
  });

  test('the list is empty when the API leaves it out', () {
    final result = DiagnosticResult.fromJson({'attempt_id': 'a1'});

    expect(result.unitsNotChecked, isEmpty);
  });

  test('builds the message for one unit and for several', () {
    const u9 = UnitRef(unitCode: 'U9', unitTitle: 'Microbiology');
    const u10 = UnitRef(unitCode: 'U10', unitTitle: 'Applied Biology');

    expect(
      unitsNotCheckedText([u10]),
      "Not checked yet: Unit 10. We'll add it when questions are ready.",
    );
    expect(
      unitsNotCheckedText([u9, u10]),
      "Not checked yet: Unit 9, Unit 10. We'll add them when questions are "
      'ready.',
    );
  });
}
