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
}
