import '../../../core/domain/app_failure.dart';
import '../../../core/domain/local_date.dart';
import '../../record_expenses/domain/expense.dart';
import 'category_filter.dart';
import 'history_range.dart';

enum HistoryStatus {
  loading,
  available,
  emptyPeriod,
  noFilterMatches,
  emptyEver,
  unavailable,
  stale,
}

/// One period plus the filter that produced a snapshot.
class HistoryQuery {
  const HistoryQuery({
    required this.period,
    required this.filter,
  });

  final HistoryPeriod period;
  final CategoryFilter filter;
}

/// One local calendar date within the selected period.
class DateGroup {
  const DateGroup({
    required this.date,
    required this.expenses,
    required this.subtotalMinor,
  });

  final LocalDate date;
  final List<Expense> expenses;
  final int subtotalMinor;
}

/// Consistent read result for one selection and filter.
///
/// Rows, date groups, count, subtotals and total all derive from the same
/// ordered row list. A failure never produces a zero-filled snapshot.
class HistorySnapshot {
  const HistorySnapshot({
    required this.period,
    required this.filter,
    required this.groups,
    required this.count,
    required this.totalMinor,
    required this.hasAnyExpenses,
    required this.latestExpenseDate,
    required this.status,
  });

  final HistoryPeriod period;
  final CategoryFilter filter;
  final List<DateGroup> groups;
  final int count;
  final int totalMinor;
  final bool hasAnyExpenses;
  final LocalDate? latestExpenseDate;
  final HistoryStatus status;

  /// Derives groups, count, subtotals and total from [rows].
  ///
  /// [rows] must already be ordered `expense_date DESC, save_sequence DESC`.
  /// Checked signed-64-bit accumulation maps overflow to
  /// `calculationOverflow`; values are never wrapped, clamped or rounded.
  static Result<HistorySnapshot> derive({
    required HistoryPeriod period,
    required CategoryFilter filter,
    required List<Expense> rows,
    required bool hasAnyExpenses,
    required LocalDate? latestExpenseDate,
  }) {
    final groups = <DateGroup>[];
    var total = BigInt.zero;
    var count = 0;
    LocalDate? groupDate;
    var groupExpenses = <Expense>[];
    var groupSubtotal = BigInt.zero;
    AppFailure? overflow;

    void flushGroup() {
      final date = groupDate;
      if (date == null || overflow != null) {
        return;
      }
      final subtotal = _toSigned64(groupSubtotal);
      if (subtotal == null) {
        overflow = const AppFailure(AppFailureCode.calculationOverflow);
        return;
      }
      groups.add(
        DateGroup(
          date: date,
          expenses: List<Expense>.unmodifiable(groupExpenses),
          subtotalMinor: subtotal,
        ),
      );
    }

    for (final row in rows) {
      final amount = BigInt.from(row.amount.minorUnits);
      if (groupDate == null || row.date != groupDate) {
        flushGroup();
        if (overflow != null) {
          return Failure<HistorySnapshot>(overflow!);
        }
        groupDate = row.date;
        groupExpenses = <Expense>[row];
        groupSubtotal = amount;
      } else {
        groupExpenses.add(row);
        groupSubtotal += amount;
      }
      total += amount;
      count++;
    }
    flushGroup();
    if (overflow != null) {
      return Failure<HistorySnapshot>(overflow!);
    }

    final totalMinor = _toSigned64(total);
    if (totalMinor == null) {
      return const Failure<HistorySnapshot>(
        AppFailure(AppFailureCode.calculationOverflow),
      );
    }

    final HistoryStatus status;
    if (!hasAnyExpenses) {
      status = HistoryStatus.emptyEver;
    } else if (count == 0 && filter is SelectedCategory) {
      status = HistoryStatus.noFilterMatches;
    } else if (count == 0) {
      status = HistoryStatus.emptyPeriod;
    } else {
      status = HistoryStatus.available;
    }

    return Success(
      HistorySnapshot(
        period: period,
        filter: filter,
        groups: List<DateGroup>.unmodifiable(groups),
        count: count,
        totalMinor: totalMinor,
        hasAnyExpenses: hasAnyExpenses,
        latestExpenseDate: latestExpenseDate,
        status: status,
      ),
    );
  }

  static final BigInt _maxInt64 = BigInt.parse('9223372036854775807');
  static final BigInt _minInt64 = BigInt.parse('-9223372036854775808');

  static int? _toSigned64(BigInt value) {
    if (value > _maxInt64 || value < _minInt64) {
      return null;
    }
    return value.toInt();
  }
}
