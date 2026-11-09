import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one hundred saves reopen with exactly one row each',
      (tester) async {
    final base = Directory(
      '${await getDatabasesPath()}/expense_tracker_reopen_integration',
    );
    if (base.existsSync()) {
      base.deleteSync(recursive: true);
    }
    base.createSync(recursive: true);

    final repository = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: FixedDirectoryStoragePolicy(base.path),
    );
    expect(await repository.initialize(), isA<Success<void>>());

    final today = LocalDate.today();
    final ids = <String>{};
    for (var index = 0; index < 100; index++) {
      final id = 'reopen-${index.toString().padLeft(3, '0')}';
      ids.add(id);
      final result = await repository.createExpense(
        ImmutableSubmission(
          id: ExpenseId(id),
          amount: Money.parse('1.00').value!,
          categoryId: index.isEven ? 'builtin.food-drinks' : 'builtin.transport',
          date: today,
          note: index.isEven ? Note.canonical('row $index') : null,
        ),
      );
      expect(result.isSuccess, isTrue);
    }
    await repository.dispose();

    final reopened = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: FixedDirectoryStoragePolicy(base.path),
    );
    expect(await reopened.initialize(), isA<Success<void>>());

    final snapshot = (await reopened.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, 100);
    expect(snapshot.todayTotalMinor, 10000);
    expect(snapshot.todayRows.length, 100);
    expect(
      snapshot.todayRows.map((expense) => expense.id.value).toSet(),
      ids,
    );
    expect(
      snapshot.todayRows.map((expense) => expense.id.value).toSet().length,
      snapshot.todayRows.length,
    );
    expect(
      snapshot.todayTotalMinor,
      snapshot.todayRows.fold<int>(
        0,
        (total, expense) => total + expense.amount.minorUnits,
      ),
    );

    await reopened.dispose();
  });
}
