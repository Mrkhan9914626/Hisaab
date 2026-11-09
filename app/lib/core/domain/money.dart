enum MoneyParseError {
  blank,
  invalidFormat,
  belowMinimum,
  aboveMaximum,
}

/// Exact PKR amount stored as integer paisa.
///
/// No binary floating point is used anywhere in parsing, comparison or
/// formatting.
class Money implements Comparable<Money> {
  const Money._(this.minorUnits);

  static const int minMinorUnits = 1;
  static const int maxMinorUnits = 99999999900;

  final int minorUnits;

  static Money fromMinorUnits(int minorUnits) {
    if (minorUnits < minMinorUnits || minorUnits > maxMinorUnits) {
      throw ArgumentError.value(minorUnits, 'minorUnits', 'Outside approved PKR bounds');
    }
    return Money._(minorUnits);
  }

  /// Parses user amount input.
  ///
  /// Accepted: outer whitespace, ASCII digits, optional period and one or two
  /// fraction digits, e.g. `650`, `650.2`, `650.25`.
  static ({Money? value, MoneyParseError? error}) parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (value: null, error: MoneyParseError.blank);
    }

    final match = RegExp(r'^([0-9]+)(?:\.([0-9]{1,2}))?$').firstMatch(trimmed);
    if (match == null) {
      return (value: null, error: MoneyParseError.invalidFormat);
    }

    final whole = BigInt.parse(match.group(1)!);
    final fractionText = match.group(2) ?? '';
    final fraction = BigInt.parse(
      fractionText.isEmpty ? '0' : fractionText.padRight(2, '0'),
    );
    final total = whole * BigInt.from(100) + fraction;

    if (total < BigInt.from(minMinorUnits)) {
      return (value: null, error: MoneyParseError.belowMinimum);
    }
    if (total > BigInt.from(maxMinorUnits)) {
      return (value: null, error: MoneyParseError.aboveMaximum);
    }
    return (value: Money._(total.toInt()), error: null);
  }

  int get wholeRupees => minorUnits ~/ 100;
  int get paisa => minorUnits % 100;

  /// Formats as `PKR 1,234.50` using integer arithmetic only.
  String formatPkr() => formatMinorUnits(minorUnits);

  static String formatMinorUnits(int minorUnits) {
    if (minorUnits < 0) {
      throw ArgumentError.value(minorUnits, 'minorUnits', 'Totals cannot be negative');
    }
    final whole = minorUnits ~/ 100;
    final fraction = minorUnits % 100;
    return 'PKR ${_group(whole.toString())}.${fraction.toString().padLeft(2, '0')}';
  }

  static String _group(String digits) {
    if (digits.length <= 3) {
      return digits;
    }
    final buffer = StringBuffer();
    final firstGroup = digits.length % 3 == 0 ? 3 : digits.length % 3;
    buffer.write(digits.substring(0, firstGroup));
    for (var index = firstGroup; index < digits.length; index += 3) {
      buffer.write(',');
      buffer.write(digits.substring(index, index + 3));
    }
    return buffer.toString();
  }

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => formatPkr();
}
