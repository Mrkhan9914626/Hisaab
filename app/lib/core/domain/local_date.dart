/// Validated Gregorian civil date with no timezone or instant semantics.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  factory LocalDate(int year, int month, int day) {
    if (!isValidDate(year, month, day)) {
      throw ArgumentError('Invalid Gregorian date: $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        return isLeapYear(year) ? 29 : 28;
      default:
        return 0;
    }
  }

  static bool isValidDate(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12) {
      return false;
    }
    return day >= 1 && day <= daysInMonth(year, month);
  }

  static LocalDate? tryCreate(int year, int month, int day) =>
      isValidDate(year, month, day) ? LocalDate._(year, month, day) : null;

  static LocalDate? tryParse(String value) {
    final match =
        RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }
    return tryCreate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static LocalDate fromDateTime(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  static LocalDate today([DateTime? now]) => fromDateTime(now ?? DateTime.now());

  DateTime toDateTime() => DateTime(year, month, day);

  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  LocalDate get firstOfMonth => LocalDate._(year, month, 1);

  /// First day of the next month, or `null` for the last representable month.
  LocalDate? get nextMonthStart {
    if (month == 12) {
      return year == 9999 ? null : LocalDate._(year + 1, 1, 1);
    }
    return LocalDate._(year, month + 1, 1);
  }

  bool get isLastMonthOfDomain => year == 9999 && month == 12;

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  bool isSameDay(LocalDate other) => compareTo(other) == 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
