import '../domain/money.dart';

class MoneyText {
  const MoneyText._();

  static String format(Money money) => money.formatPkr();

  static String formatMinor(int minorUnits) =>
      Money.formatMinorUnits(minorUnits);
}
