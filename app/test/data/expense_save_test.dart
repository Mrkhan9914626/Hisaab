import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/data/write_cancellation.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

void main() {
  late Directory directory;
  late DatabaseFactory factory;
  late ExpenseRepository repository;
  final today = LocalDate(2026, 11, 8);

  setUp(() async {
    directory = createTempDirectory('expense_save_');
    factory = createTestDatabaseFactory();
    repository = ExpenseRepository(
      factory: factory,
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    expect(await repository.initialize(), isA<Success<void>>());
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('saves the exact amount, category, date and note', () async {
    final result = await repository.createExpense(
      makeSubmission(
        id: 'save-1',
        amountText: '650.25',
        categoryId: foodCategoryId,
        date: today,
        note: 'Lunch',
      ),
    );
    expect(result, isA<Success<Expense>>());
    final expense = (result as Success<Expense>).value;
    expect(expense.amount.minorUnits, 65025);
    expect(expense.category.id, foodCategoryId);
    expect(expense.date, today);
    expect(expense.note?.text, 'Lunch');

    final overview = (await repository.loadOverview(today)).valueOrNull!;
    expect(overview.todayCount, 1);
    expect(overview.todayTotalMinor, 65025);
  });

  test('same ID with the same payload is saved once', () async {
    final submission = makeSubmission(
      id: 'retry-1',
      amountText: '10.10',
      categoryId: foodCategoryId,
      date: today,
    );
    expect(await repository.createExpense(submission), isA<Success<Expense>>());
    expect(await repository.createExpense(submission), isA<Success<Expense>>());

    final overview = (await repository.loadOverview(today)).valueOrNull!;
    expect(overview.todayCount, 1);
    expect(overview.todayTotalMinor, 1010);
  });

  test('same ID with a different payload is an integrity failure', () async {
    final first = makeSubmission(
      id: 'conflict-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );
    final second = makeSubmission(
      id: 'conflict-1',
      amountText: '11.00',
      categoryId: foodCategoryId,
      date: today,
    );
    await repository.createExpense(first);
    final result = await repository.createExpense(second);
    expect(result, isA<Failure<Expense>>());
    expect(
      (result as Failure<Expense>).failure.code,
      AppFailureCode.integrityFailure,
    );
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 1);
  });

  test('two deliberate equal-value purchases are distinct', () async {
    final first = makeSubmission(
      id: 'purchase-1',
      amountText: '20.00',
      categoryId: foodCategoryId,
      date: today,
    );
    final second = makeSubmission(
      id: 'purchase-2',
      amountText: '20.00',
      categoryId: foodCategoryId,
      date: today,
    );
    await repository.createExpense(first);
    await repository.createExpense(second);
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 2);
  });

  test('an earlier in-month date is retained but stays out of today', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'earlier-1',
        amountText: '50.05',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 11, 5),
      ),
    );
    final overview = (await repository.loadOverview(today)).valueOrNull!;
    expect(overview.todayCount, 0);
    expect(overview.todayRows, isEmpty);
    expect(overview.monthTotalMinor, 5005);
    expect(overview.hasAnyExpenses, isTrue);
  });

  test('an unknown category is an integrity failure', () async {
    final result = await repository.createExpense(
      makeSubmission(
        id: 'missing-category',
        amountText: '10.00',
        categoryId: 'builtin.missing',
        date: today,
      ),
    );
    expect(result, isA<Failure<Expense>>());
    expect(
      (result as Failure<Expense>).failure.code,
      AppFailureCode.integrityFailure,
    );
  });

  test('an archived category cannot receive new expenses', () async {
    final admin = await factory.openDatabase(
      '${directory.path}/${ExpenseRepository.databaseFileName}',
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await admin.update(
      'categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [transportCategoryId],
    );
    await admin.close();

    final result = await repository.createExpense(
      makeSubmission(
        id: 'archived-category',
        amountText: '10.00',
        categoryId: transportCategoryId,
        date: today,
      ),
    );
    expect(result, isA<Failure<Expense>>());
    expect(
      (result as Failure<Expense>).failure.code,
      AppFailureCode.integrityFailure,
    );
  });

  test('a pre-cancelled write rolls back with no row', () async {
    final cancellation = WriteCancellation()..isCancelled = true;
    await expectLater(
      repository.createExpense(
        makeSubmission(
          id: 'cancelled-1',
          amountText: '10.00',
          categoryId: foodCategoryId,
          date: today,
        ),
        cancellation: cancellation,
      ),
      throwsA(isA<CancellationRollback>()),
    );
    final overview = (await repository.loadOverview(today)).valueOrNull!;
    expect(overview.todayCount, 0);
    expect(overview.hasAnyExpenses, isFalse);
  });
}
