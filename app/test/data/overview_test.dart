import 'dart:io';

import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  late Directory directory;
  late ExpenseRepository repository;
  final today = LocalDate(2026, 11, 8);

  setUp(() async {
    directory = createTempDirectory('expense_overview_');
    repository = await openRepository(directory);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('empty store reports no history and zero totals', () async {
    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.hasAnyExpenses, isFalse);
    expect(snapshot.todayRows, isEmpty);
    expect(snapshot.todayCount, 0);
    expect(snapshot.todayTotalMinor, 0);
    expect(snapshot.monthTotalMinor, 0);
  });

  test('derives today rows, count and month total from one snapshot', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'today-1',
        amountText: '100.10',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    await repository.createExpense(
      makeSubmission(
        id: 'today-2',
        amountText: '200.20',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    await repository.createExpense(
      makeSubmission(
        id: 'month-1',
        amountText: '50.05',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 11, 5),
      ),
    );
    await repository.createExpense(
      makeSubmission(
        id: 'previous-month-1',
        amountText: '900.00',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 10, 31),
      ),
    );

    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.hasAnyExpenses, isTrue);
    expect(snapshot.todayCount, 2);
    expect(snapshot.todayTotalMinor, 30030);
    expect(snapshot.monthTotalMinor, 35035);
    expect(snapshot.todayRows.map((expense) => expense.id.value), [
      'today-2',
      'today-1',
    ]);
  });

  test('uses inclusive first day and exclusive next month start', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'first-of-month',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 11, 1),
      ),
    );
    await repository.createExpense(
      makeSubmission(
        id: 'next-month',
        amountText: '20.00',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 12, 1),
      ),
    );

    final november = (await repository.loadOverview(today)).valueOrNull!;
    expect(november.monthTotalMinor, 1000);
    expect(november.todayRows, isEmpty);

    final december = (await repository
        .loadOverview(LocalDate(2026, 12, 1)))
        .valueOrNull!;
    expect(december.monthTotalMinor, 2000);
    expect(december.todayCount, 1);
  });

  test('keeps exact totals above one expense maximum', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'max-1',
        amountText: '999999999.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    await repository.createExpense(
      makeSubmission(
        id: 'max-2',
        amountText: '999999999.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayTotalMinor, 199999999800);
    expect(snapshot.monthTotalMinor, 199999999800);
  });

  test('saved dates are not rewritten by a different day', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'stable-date',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    final later = (await repository
        .loadOverview(LocalDate(2026, 11, 9)))
        .valueOrNull!;
    expect(later.todayRows, isEmpty);
    expect(later.monthTotalMinor, 1000);

    final earlier = (await repository
        .loadOverview(LocalDate(2026, 11, 7)))
        .valueOrNull!;
    expect(earlier.todayRows, isEmpty);
    expect(earlier.monthTotalMinor, 1000);
  });
}
