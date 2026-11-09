import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
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
    directory = createTempDirectory('expense_details_');
    factory = createTestDatabaseFactory();
    repository = ExpenseRepository(
      factory: factory,
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    await repository.initialize();
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('returns joined category metadata, date and note', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'details-1',
        amountText: '12.34',
        categoryId: foodCategoryId,
        date: today,
        note: 'Tea',
      ),
    );

    final result = await repository.loadExpense(const ExpenseId('details-1'));
    expect(result, isA<Success<Expense>>());
    final expense = (result as Success<Expense>).value;
    expect(expense.amount.minorUnits, 1234);
    expect(expense.category.name, 'Food & drinks');
    expect(expense.category.iconKey, 'food_drinks');
    expect(expense.date, today);
    expect(expense.note?.text, 'Tea');
  });

  test('an archived category remains readable on a saved expense', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'archived-1',
        amountText: '5.00',
        categoryId: transportCategoryId,
        date: today,
      ),
    );
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

    final result = await repository.loadExpense(const ExpenseId('archived-1'));
    final expense = (result as Success<Expense>).value;
    expect(expense.category.name, 'Transport');
    expect(expense.category.isActive, isFalse);
  });

  test('a missing record is an integrity failure, never a blank expense', () async {
    final result = await repository.loadExpense(const ExpenseId('missing'));
    expect(result, isA<Failure<Expense>>());
    expect(
      (result as Failure<Expense>).failure.code,
      AppFailureCode.integrityFailure,
    );
  });

  test('a missing note is represented as null', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'no-note-1',
        amountText: '5.00',
        categoryId: foodCategoryId,
        date: today,
        note: '   ',
      ),
    );
    final result = await repository.loadExpense(const ExpenseId('no-note-1'));
    expect((result as Success<Expense>).value.note, isNull);
  });
}
