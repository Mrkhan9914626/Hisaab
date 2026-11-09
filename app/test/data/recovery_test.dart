import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/data/write_cancellation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

void main() {
  late Directory directory;
  final today = LocalDate(2026, 11, 8);

  setUp(() {
    directory = createTempDirectory('expense_recovery_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('successful saves survive close and reopen exactly once', () async {
    final repository = await openRepository(directory);
    for (var index = 0; index < 10; index++) {
      await repository.createExpense(
        makeSubmission(
          id: 'recovery-$index',
          amountText: '1.00',
          categoryId: foodCategoryId,
          date: today,
        ),
      );
    }
    await repository.dispose();

    final reopened = await openRepository(directory);
    final snapshot = (await reopened.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, 10);
    expect(snapshot.todayTotalMinor, 1000);
    expect(snapshot.todayRows.map((expense) => expense.id.value).toSet(), {
      for (var index = 0; index < 10; index++) 'recovery-$index',
    });
    await reopened.dispose();
  });

  test('a cancelled write leaves earlier saved rows unchanged', () async {
    final repository = await openRepository(directory);
    await repository.createExpense(
      makeSubmission(
        id: 'kept-before-cancel',
        amountText: '25.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    final cancellation = WriteCancellation()..isCancelled = true;
    await expectLater(
      repository.createExpense(
        makeSubmission(
          id: 'never-written',
          amountText: '99.00',
          categoryId: foodCategoryId,
          date: today,
        ),
        cancellation: cancellation,
      ),
      throwsA(isA<CancellationRollback>()),
    );

    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, 1);
    expect(snapshot.todayTotalMinor, 2500);
    expect(snapshot.todayRows.single.id.value, 'kept-before-cancel');
    await repository.dispose();
  });

  test('reopening a corrupt store never silently resets history', () async {
    final repository = await openRepository(directory);
    await repository.createExpense(
      makeSubmission(
        id: 'before-corruption',
        amountText: '25.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    await repository.dispose();

    final file =
        File('${directory.path}/${ExpenseRepository.databaseFileName}');
    file.writeAsStringSync('corrupted beyond recovery');

    final reopened = ExpenseRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    final result = await reopened.initialize();
    expect(result, isNot(isA<Success<void>>()));
    expect(reopened.isInitialized, isFalse);
  });
}
