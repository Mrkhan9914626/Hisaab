import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects invalid Gregorian dates without normalizing', () {
    expect(LocalDate.tryCreate(2023, 2, 29), isNull);
    expect(LocalDate.tryCreate(2024, 2, 29), isNotNull);
    expect(LocalDate.tryCreate(1900, 2, 29), isNull);
    expect(LocalDate.tryCreate(2000, 2, 29), isNotNull);
    expect(LocalDate.tryCreate(2024, 4, 31), isNull);
    expect(LocalDate.tryCreate(0, 1, 1), isNull);
    expect(LocalDate.tryCreate(1, 1, 1), isNotNull);
    expect(LocalDate.tryCreate(9999, 12, 31), isNotNull);
    expect(LocalDate.tryCreate(10000, 1, 1), isNull);
  });

  test('parses and formats canonical YYYY-MM-DD', () {
    final date = LocalDate.tryParse('2026-11-08');
    expect(date, isNotNull);
    expect(date!.iso, '2026-11-08');
    expect(LocalDate.tryParse('2023-02-29'), isNull);
    expect(LocalDate.tryParse('8-11-2026'), isNull);
  });

  test('compares civil values, not instants', () {
    expect(
      LocalDate(2026, 11, 8).compareTo(LocalDate(2026, 11, 9)),
      lessThan(0),
    );
    expect(
      LocalDate(2026, 12, 31).compareTo(LocalDate(2027, 1, 1)),
      lessThan(0),
    );
  });

  test('builds inclusive month start and exclusive next start', () {
    final date = LocalDate(2026, 11, 8);
    expect(date.firstOfMonth.iso, '2026-11-01');
    expect(date.nextMonthStart!.iso, '2026-12-01');
    expect(LocalDate(2026, 12, 15).nextMonthStart!.iso, '2027-01-01');
  });

  test('uses a predicate for the final representable month', () {
    final lastMonth = LocalDate(9999, 12, 31);
    expect(lastMonth.nextMonthStart, isNull);
    expect(lastMonth.isLastMonthOfDomain, isTrue);
  });

  test('today uses the local calendar date', () {
    expect(
      LocalDate.today(DateTime(2026, 11, 8, 23, 59)),
      LocalDate(2026, 11, 8),
    );
  });
}
