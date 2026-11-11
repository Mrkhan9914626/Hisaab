import 'dart:io';

import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/presentation/add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  late Directory directory;
  late ExpenseRepository repository;
  late SaveCoordinator coordinator;

  setUp(() async {
    directory = createTempDirectory('add_expense_save_');
    repository = await openRepository(directory);
    coordinator = SaveCoordinator(repository);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  testWidgets('a valid save persists one expense and returns the expense',
      (tester) async {
    Expense? popResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  popResult = await Navigator.of(context).push<Expense>(
                    MaterialPageRoute<Expense>(
                      builder: (context) => AddExpenseScreen(
                        repository: repository,
                        coordinator: coordinator,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '650.25');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & drinks').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lunch');

    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(popResult, isNotNull);
    expect(popResult!.amount.minorUnits, 65025);
    final snapshot =
        (await repository.loadOverview(LocalDate.today())).valueOrNull!;
    expect(snapshot.todayCount, 1);
    expect(snapshot.todayTotalMinor, 65025);
    expect(snapshot.todayRows.single.category.id, foodCategoryId);
    expect(snapshot.todayRows.single.note?.text, 'Lunch');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('double tapping Save writes only one row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<Expense>(
                    MaterialPageRoute<Expense>(
                      builder: (context) => AddExpenseScreen(
                        repository: repository,
                        coordinator: coordinator,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '10.00');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & drinks').last);
    await tester.pumpAndSettle();

    final save = find.text('Save expense');
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();

    final snapshot =
        (await repository.loadOverview(LocalDate.today())).valueOrNull!;
    expect(snapshot.todayCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
