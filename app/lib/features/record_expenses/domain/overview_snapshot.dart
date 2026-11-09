import '../../../core/domain/local_date.dart';
import 'expense.dart';

class OverviewSnapshot {
  const OverviewSnapshot({
    required this.today,
    required this.todayRows,
    required this.todayCount,
    required this.todayTotalMinor,
    required this.monthTotalMinor,
    required this.hasAnyExpenses,
  });

  final LocalDate today;
  final List<Expense> todayRows;
  final int todayCount;
  final int todayTotalMinor;
  final int monthTotalMinor;
  final bool hasAnyExpenses;
}
