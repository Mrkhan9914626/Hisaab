import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:expense_tracker/features/record_expenses/presentation/expense_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('day, month and year boundaries show an exact Overview',
      (tester) async {
    final base = Directory(
      '${await getDatabasesPath()}/expense_tracker_overview_integration',
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
    final firstOfMonth = today.firstOfMonth;
    final previousMonth = firstOfMonth.month == 1 ? 12 : firstOfMonth.month - 1;
    final previousYear =
        firstOfMonth.month == 1 ? firstOfMonth.year - 1 : firstOfMonth.year;

    final todayExpense = ImmutableSubmission(
      id: const ExpenseId('overview-boundary-today'),
      amount: Money.parse('10.00').value!,
      categoryId: 'builtin.food-drinks',
      date: today,
      note: Note.canonical('Today lunch'),
    );
    final firstExpense = ImmutableSubmission(
      id: const ExpenseId('overview-boundary-first'),
      amount: Money.parse('5.00').value!,
      categoryId: 'builtin.transport',
      date: firstOfMonth,
      note: null,
    );

    expect((await repository.createExpense(todayExpense)).isSuccess, isTrue);
    expect((await repository.createExpense(firstExpense)).isSuccess, isTrue);
    if (previousYear >= 1) {
      final previousLast = LocalDate(
        previousYear,
        previousMonth,
        LocalDate.daysInMonth(previousYear, previousMonth),
      );
      expect(
        (await repository.createExpense(
          ImmutableSubmission(
            id: const ExpenseId('overview-boundary-previous'),
            amount: Money.parse('20.00').value!,
            categoryId: 'builtin.other',
            date: previousLast,
            note: null,
          ),
        ))
            .isSuccess,
        isTrue,
      );
    }

    final firstIsToday = firstOfMonth == today;
    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, firstIsToday ? 2 : 1);
    expect(snapshot.todayTotalMinor, firstIsToday ? 1500 : 1000);
    expect(snapshot.monthTotalMinor, 1500);
    expect(snapshot.hasAnyExpenses, isTrue);
    expect(
      snapshot.todayRows.map((expense) => expense.id.value),
      contains('overview-boundary-today'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ExpenseDetailsScreen(
          repository: repository,
          expenseId: todayExpense.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PKR 10.00'), findsOneWidget);
    expect(find.text('Food & drinks'), findsOneWidget);
    expect(find.text('Today lunch'), findsOneWidget);

    await repository.dispose();
  });
}
