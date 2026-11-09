import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/domain/overview_snapshot.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  late Directory directory;
  late ExpenseRepository repository;
  final today = LocalDate(2026, 11, 8);

  setUp(() async {
    directory = createTempDirectory('failure_paths_');
    repository = await openRepository(directory);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('a write after storage loss is an honest failure, never Saved',
      () async {
    await repository.dispose();

    final result = await repository.createExpense(
      makeSubmission(
        id: 'failed-write',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    expect(result, isA<Failure<Expense>>());
    expect(
      (result as Failure<Expense>).failure.code,
      AppFailureCode.storageUnavailable,
    );
  });

  test('a read after storage loss never fabricates an empty snapshot',
      () async {
    await repository.dispose();

    final result = await repository.loadOverview(today);

    expect(result, isA<Failure<OverviewSnapshot>>());
    expect(
      (result as Failure<OverviewSnapshot>).failure.code,
      AppFailureCode.storageUnavailable,
    );
    expect(result.valueOrNull, isNull);
  });

  test('a failed details read never fabricates a blank expense', () async {
    await repository.dispose();

    final result = await repository.loadExpense(const ExpenseId('anything'));

    expect(result, isA<Failure<Expense>>());
    expect(result.valueOrNull, isNull);
  });
}
