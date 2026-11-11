import 'local_date.dart';

/// Pure Gregorian civil-date arithmetic used to derive history periods.
///
/// Every operation works on calendar dates only. No UTC instant, elapsed
/// duration or `DateTime.add` is used, so timezone changes and daylight-saving
/// transitions cannot move a saved date into another period.
class CalendarRange {
  const CalendarRange._();

  static final LocalDate domainStart = LocalDate(1, 1, 1);
  static final LocalDate domainEnd = LocalDate(9999, 12, 31);

  /// Weekday for [date], where Monday is `1` and Sunday is `7`.
  static int weekday(LocalDate date) =>
      ((_daysFromCivil(date.year, date.month, date.day) + 3) % 7) + 1;

  /// Adds civil days to [date].
  ///
  /// Returns `null` when the result would fall outside the representable
  /// `0001-01-01`–`9999-12-31` domain, so year 10000 is never constructed.
  static LocalDate? addDays(LocalDate date, int days) {
    if (days == 0) {
      return date;
    }
    var year = date.year;
    var month = date.month;
    var day = date.day;

    if (days > 0) {
      for (var step = 0; step < days; step++) {
        final daysInMonth = LocalDate.daysInMonth(year, month);
        if (day < daysInMonth) {
          day++;
        } else if (month < 12) {
          month++;
          day = 1;
        } else {
          if (year == 9999) {
            return null;
          }
          year++;
          month = 1;
          day = 1;
        }
      }
    } else {
      for (var step = 0; step < -days; step++) {
        if (day > 1) {
          day--;
        } else if (month > 1) {
          month--;
          day = LocalDate.daysInMonth(year, month);
        } else {
          if (year == 1) {
            return null;
          }
          year--;
          month = 12;
          day = 31;
        }
      }
    }

    return LocalDate(year, month, day);
  }

  /// Adds calendar months to [date], clamping the day to the target month.
  ///
  /// Returns `null` when the result would leave the representable domain.
  static LocalDate? addMonthsClamped(LocalDate date, int months) {
    final totalMonths =
        (date.year - 1) * 12 + (date.month - 1) + months;
    final year = _floorDiv(totalMonths, 12) + 1;
    final month = (totalMonths % 12) + 1;
    if (year < 1 || year > 9999) {
      return null;
    }
    final daysInMonth = LocalDate.daysInMonth(year, month);
    final day = date.day <= daysInMonth ? date.day : daysInMonth;
    return LocalDate(year, month, day);
  }

  static LocalDate monthStart(LocalDate date) =>
      LocalDate(date.year, date.month, 1);

  static LocalDate monthEnd(LocalDate date) => LocalDate(
        date.year,
        date.month,
        LocalDate.daysInMonth(date.year, date.month),
      );

  /// Monday of the week containing [date], or `null` before the domain start.
  static LocalDate? weekStart(LocalDate date) =>
      addDays(date, -(weekday(date) - 1));

  /// Sunday of the week containing [date], or `null` after the domain end.
  static LocalDate? weekEnd(LocalDate date) {
    final start = weekStart(date);
    if (start == null) {
      return null;
    }
    return addDays(start, 6);
  }

  static int _floorDiv(int dividend, int divisor) =>
      (dividend - (dividend % divisor)) ~/ divisor;

  /// Days since the civil epoch `1970-01-01` (a Thursday).
  static int _daysFromCivil(int year, int month, int day) {
    final adjustedYear = year - (month <= 2 ? 1 : 0);
    final era = (adjustedYear >= 0 ? adjustedYear : adjustedYear - 399) ~/ 400;
    final yearOfEra = adjustedYear - era * 400;
    final dayOfYear =
        (153 * (month + (month > 2 ? -3 : 9)) + 2) ~/ 5 + day - 1;
    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }
}
