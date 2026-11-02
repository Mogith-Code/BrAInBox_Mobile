import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.thousands', () {
    test('adds a comma every three digits', () {
      expect(Formatters.thousands(0), '0');
      expect(Formatters.thousands(999), '999');
      expect(Formatters.thousands(1000), '1,000');
      expect(Formatters.thousands(2418), '2,418');
      expect(Formatters.thousands(41208), '41,208');
      expect(Formatters.thousands(1234567), '1,234,567');
    });

    test('keeps the minus sign', () {
      expect(Formatters.thousands(-1500), '-1,500');
    });
  });

  test('Formatters.unitLabel accepts "6" and "U6"', () {
    expect(Formatters.unitLabel('6'), 'Unit 6');
    expect(Formatters.unitLabel('U6'), 'Unit 6');
    expect(Formatters.unitLabel('u10'), 'Unit 10');
    expect(Formatters.unitLabel(' 3 '), 'Unit 3');
    expect(Formatters.unitLabel(''), '');
    expect(Formatters.unitLabel(null), '');
  });

  test('Formatters.waitTime rounds up to minutes and uses words', () {
    expect(Formatters.waitTime(0), '1 minute');
    expect(Formatters.waitTime(45), '1 minute');
    expect(Formatters.waitTime(61), '2 minutes');
    expect(Formatters.waitTime(600), '10 minutes');
    expect(Formatters.waitTime(3600), '1 hour');
    expect(Formatters.waitTime(5400), '1 hour 30 minutes');
    expect(Formatters.waitTime(7260), '2 hours 1 minute');
    expect(Formatters.waitTime(86400), '24 hours');
  });
}
