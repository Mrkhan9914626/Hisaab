import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/data/write_cancellation.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:expense_tracker/features/record_expenses/presentation/add_expense_screen.dart';
import 'package:expense_tracker/features/record_expenses/presentation/expense_details_screen.dart';
import 'package:expense_tracker/features/record_expenses/presentation/overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

class _WriteFailingRepository extends ExpenseRepository {
  _WriteFailingRepository({
    required super.factory,
    required super.storagePolicy,
  });

  @override
  Future<Result<Expense>> createExpense(
    ImmutableSubmission submission, {
    WriteCancellation? cancellation,
  }) async =>
      const Failure<Expense>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
}

void main() {
  testWidgets('unavailable Overview shows Retry and never zero spending',
      (tester) async {
    final directory = createTempDirectory('failure_overview_');
    final repository = await openRepository(directory);
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });
    await repository.dispose();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OverviewScreen(
          repository: repository,
          coordinator: SaveCoordinator(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Saved data is unavailable right now. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('PKR 0.00'), findsNothing);
    expect(find.text('No expenses yet'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('details failure offers Retry and Back without a blank amount',
      (tester) async {
    final directory = createTempDirectory('failure_details_');
    final repository = await openRepository(directory);
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ExpenseDetailsScreen(
          repository: repository,
          expenseId: const ExpenseId('missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The saved records could not be verified.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.textContaining('PKR '), findsNothing);

    await repository.dispose();
  });

  testWidgets('a write failure keeps every form value and shows Retry',
      (tester) async {
    final directory = createTempDirectory('failure_write_');
    final repository = _WriteFailingRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    await repository.initialize();
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddExpenseScreen(
          repository: repository,
          coordinator: SaveCoordinator(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '10.00');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & drinks').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'keep me');

    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Saved data is unavailable right now. Try again.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('10.00'), findsOneWidget);
    expect(find.text('keep me'), findsOneWidget);
    expect(find.textContaining('Saved PKR'), findsNothing);

    await repository.dispose();
  });
}
