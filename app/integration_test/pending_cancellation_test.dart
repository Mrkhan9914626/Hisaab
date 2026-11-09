import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cancellation reports one terminal outcome and never duplicates',
      (tester) async {
    final base = Directory(
      '${await getDatabasesPath()}/expense_tracker_cancel_integration',
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
    final coordinator = SaveCoordinator(repository);
    final today = LocalDate.today();

    final submission = ImmutableSubmission(
      id: const ExpenseId('integration-cancel-1'),
      amount: Money.parse('10.00').value!,
      categoryId: 'builtin.food-drinks',
      date: today,
      note: null,
    );

    final operation = coordinator.begin(submission);
    final outcome = await coordinator.requestCancellation(submission.id);
    expect(outcome, anyOf(isA<Cancelled>(), isA<Saved>()));
    await operation.outcome;

    final snapshot = (await repository.loadOverview(today)).valueOrNull!;
    expect(snapshot.todayCount, outcome is Saved ? 1 : 0);

    final retried = coordinator.begin(submission);
    await retried.outcome;
    final afterRetry = (await repository.loadOverview(today)).valueOrNull!;
    expect(afterRetry.todayCount, 1);

    await repository.dispose();
  });
}
