import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/presentation/money_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats Money with grouping and exactly two decimals', () {
    expect(
      MoneyText.format(Money.parse('1234.5').value!),
      'PKR 1,234.50',
    );
  });

  test('formats totals including zero and large exact sums', () {
    expect(MoneyText.formatMinor(0), 'PKR 0.00');
    expect(
      MoneyText.formatMinor(999999999000000),
      'PKR 9,999,999,990,000.00',
    );
  });
}
