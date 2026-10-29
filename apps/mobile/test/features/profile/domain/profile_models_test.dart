import 'package:brainbox_mobile/features/profile/domain/profile_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confidence labels by range', () {
    expect(confidenceLabel(0), 'Not at all');
    expect(confidenceLabel(20), 'Not at all');
    expect(confidenceLabel(21), 'A little');
    expect(confidenceLabel(40), 'A little');
    expect(confidenceLabel(41), 'Okay-ish');
    expect(confidenceLabel(60), 'Okay-ish');
    expect(confidenceLabel(61), 'Fairly');
    expect(confidenceLabel(80), 'Fairly');
    expect(confidenceLabel(81), 'Very');
    expect(confidenceLabel(100), 'Very');
  });

  test('weekly hours hint matches the Figma text', () {
    expect(weeklyHoursHint(10), '≈ 10 hours a week · a steady pace');
    expect(weeklyHoursHint(3), '≈ 3 hours a week · a light pace');
    expect(weeklyHoursHint(17.5), '≈ 17.5 hours a week · an intense pace');
  });

  test('options accept plain strings or objects', () {
    final options = ProfileOptions.fromJson({
      'streams': [
        {'id': 'bio', 'name': 'Biological Science'},
      ],
      'subjects': [
        {'id': 'biology', 'name': 'Biology', 'units': 10, 'available': true},
        {'id': 'chemistry', 'name': 'Chemistry', 'available': false},
      ],
      'exam_years': [2026, 2027],
      'target_grades': ['A', 'B', 'C'],
      'preferred_times': [
        {'id': 'evening', 'label': 'Evening', 'hint': '4–8 PM'},
      ],
    });
    expect(options.streams.single.name, 'Biological Science');
    expect(options.targetGrades.map((g) => g.id), ['A', 'B', 'C']);
    expect(options.subjects.last.available, isFalse);
  });
}
