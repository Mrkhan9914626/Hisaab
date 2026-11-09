import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records fractional and maximum amounts and reopens exactly',
      (tester) async {
    final base = Directory(
      '${await getDatabasesPath()}/expense_tracker_record_integration',
    );
    if (base.existsSync()) {
      base.deleteSync(recursive: true);
    }
    base.createSync(recursive: true);

    final today = LocalDate.today();
    final repository = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: FixedDirectoryStoragePolicy(base.path),
    );
    expect(await repository.initialize(), isA<Success<void>>());

    final fractional = ImmutableSubmission(
      id: const ExpenseId('integration-fractional'),
      amount: Money.parse('650.25').value!,
      categoryId: 'builtin.food-drinks',
      date: today,
      note: Note.canonical('Lunch'),
    );
    final maximum = ImmutableSubmission(
      id: const ExpenseId('integration-maximum'),
      amount: Money.parse('999999999.00').value!,
      categoryId: 'builtin.other',
      date: today,
      note: null,
    );

    expect(await repository.createExpense(fractional), isA<Success<Expense>>());
    expect(await repository.createExpense(maximum), isA<Success<Expense>>());
    await repository.dispose();

    final reopened = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: FixedDirectoryStoragePolicy(base.path),
    );
    expect(await reopened.initialize(), isA<Success<void>>());

    final snapshot = (await reopened.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, 2);
    expect(snapshot.todayTotalMinor, 100000064925);

    final savedFractional =
        (await reopened.loadExpense(fractional.id)).valueOrNull!;
    expect(savedFractional.amount.minorUnits, 65025);
    expect(savedFractional.category.id, 'builtin.food-drinks');
    expect(savedFractional.date, today);
    expect(savedFractional.note?.text, 'Lunch');

    final savedMaximum = (await reopened.loadExpense(maximum.id)).valueOrNull!;
    expect(savedMaximum.amount.minorUnits, 99999999900);
    expect(savedMaximum.category.id, 'builtin.other');
    expect(savedMaximum.note, isNull);

    await reopened.dispose();
  });
}
