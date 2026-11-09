import 'package:expense_tracker/core/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parse', () {
    test('accepts the approved bounds exactly', () {
      expect(Money.parse('0.01').value?.minorUnits, 1);
      expect(Money.parse('999999999.00').value?.minorUnits, 99999999900);
    });

    test('trims outer whitespace', () {
      expect(Money.parse('  650.25  ').value?.minorUnits, 65025);
    });

    test('accepts one or two fraction digits and leading zeros', () {
      expect(Money.parse('650.2').value?.minorUnits, 65020);
      expect(Money.parse('01.05').value?.minorUnits, 105);
    });

    test('rejects malformed, out-of-range and over-precision input', () {
      const invalid = [
        '',
        '   ',
        '0',
        '0.00',
        '-1',
        '+1',
        '1,000',
        '1e3',
        'PKR 1',
        '1.',
        '.5',
        '1.001',
        '1.2.3',
        '1 000',
        '999999999.01',
      ];
      for (final input in invalid) {
        expect(
          Money.parse(input).error,
          isNotNull,
          reason: 'Expected "$input" to be rejected',
        );
      }
    });

    test('reports the precise error reason', () {
      expect(Money.parse('').error, MoneyParseError.blank);
      expect(Money.parse('0.00').error, MoneyParseError.belowMinimum);
      expect(Money.parse('abc').error, MoneyParseError.invalidFormat);
      expect(Money.parse('999999999.01').error, MoneyParseError.aboveMaximum);
    });
  });

  group('Money formatting', () {
    test('groups thousands and always shows two decimals', () {
      expect(Money.parse('1234.5').value!.formatPkr(), 'PKR 1,234.50');
      expect(Money.parse('0.01').value!.formatPkr(), 'PKR 0.01');
      expect(
        Money.parse('999999999').value!.formatPkr(),
        'PKR 999,999,999.00',
      );
    });

    test('formats zero and large totals exactly', () {
      expect(Money.formatMinorUnits(0), 'PKR 0.00');
      expect(Money.formatMinorUnits(999999999000000),
          'PKR 9,999,999,990,000.00');
    });

    test('uses exact integer arithmetic for 0.10 + 0.20', () {
      final sum = Money.parse('0.10').value!.minorUnits +
          Money.parse('0.20').value!.minorUnits;
      expect(sum, Money.parse('0.30').value!.minorUnits);
    });
  });
}
