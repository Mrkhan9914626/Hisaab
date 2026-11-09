import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/data/write_cancellation.dart';
import 'package:expense_tracker/features/record_expenses/domain/category.dart';
import 'package:expense_tracker/features/record_expenses/domain/expense.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

class _CancellingRepository extends ExpenseRepository {
  _CancellingRepository()
      : super(
          factory: createTestDatabaseFactory(),
          storagePolicy: const FixedDirectoryStoragePolicy('/unused'),
        );

  @override
  Future<Result<Expense>> createExpense(
    ImmutableSubmission submission, {
    WriteCancellation? cancellation,
  }) async {
    throw const CancellationRollback();
  }
}

class _RetryableRepository extends ExpenseRepository {
  _RetryableRepository()
      : super(
          factory: createTestDatabaseFactory(),
          storagePolicy: const FixedDirectoryStoragePolicy('/unused'),
        );

  bool failWrites = true;

  @override
  Future<Result<Expense>> createExpense(
    ImmutableSubmission submission, {
    WriteCancellation? cancellation,
  }) async {
    if (failWrites) {
      return const Failure<Expense>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
    return Success(
      Expense(
        id: submission.id,
        saveSequence: 1,
        amount: submission.amount,
        category: const Category(
          id: foodCategoryId,
          name: 'Food & drinks',
          iconKey: 'food_drinks',
          isActive: true,
          isProtected: false,
        ),
        date: submission.date,
        note: submission.note,
      ),
    );
  }
}

class _UncertainRepository extends ExpenseRepository {
  _UncertainRepository({
    required super.factory,
    required super.storagePolicy,
  });

  bool failWrites = false;

  @override
  Future<Result<Expense>> createExpense(
    ImmutableSubmission submission, {
    WriteCancellation? cancellation,
  }) async {
    if (failWrites) {
      throw StateError('simulated lost connection');
    }
    return super.createExpense(submission, cancellation: cancellation);
  }
}

void main() {
  final today = LocalDate(2026, 11, 8);

  test('a rollback at the write boundary reports Cancelled', () async {
    final coordinator = SaveCoordinator(_CancellingRepository());
    final submission = makeSubmission(
      id: 'cancel-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );

    final outcome = await coordinator.begin(submission).outcome;
    expect(outcome, isA<Cancelled>());
  });

  test('a known-unsaved result can retry under the same ID', () async {
    final repository = _RetryableRepository();
    final coordinator = SaveCoordinator(repository);
    final submission = makeSubmission(
      id: 'retry-known-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );

    final first = await coordinator.begin(submission).outcome;
    expect(first, isA<KnownUnsaved>());

    repository.failWrites = false;
    final second = await coordinator.begin(submission).outcome;
    expect(second, isA<Saved>());
    expect((second as Saved).expense.id, submission.id);
  });

  test('reconcile rechecks a settled uncertain outcome', () async {
    final directory = createTempDirectory('coordinator_uncertain_');
    final repository = _UncertainRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });
    await repository.initialize();

    final submission = makeSubmission(
      id: 'uncertain-reconcile-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );
    await repository.createExpense(submission);
    repository.failWrites = true;

    final coordinator = SaveCoordinator(repository);
    expect(
      await coordinator.begin(submission).outcome,
      isA<OutcomeUnavailable>(),
    );

    final reconciled = await coordinator.reconcile(submission.id);
    expect(reconciled, isA<Saved>());
    expect((reconciled as Saved).expense.id, submission.id);
  });

  test('commit-wins or rollback-wins is reported exactly once', () async {
    final directory = createTempDirectory('coordinator_cancel_');
    final repository = await openRepository(directory);
    final coordinator = SaveCoordinator(repository);
    final submission = makeSubmission(
      id: 'race-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );

    final operation = coordinator.begin(submission);
    final outcome = await coordinator.requestCancellation(submission.id);
    expect(outcome, anyOf(isA<Cancelled>(), isA<Saved>()));

    final overview = (await repository.loadOverview(today)).valueOrNull!;
    if (outcome is Saved) {
      expect(overview.todayCount, 1);
    } else {
      expect(overview.todayCount, 0);
    }

    await operation.outcome;
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });
}
