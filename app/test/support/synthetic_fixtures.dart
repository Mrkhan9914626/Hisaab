import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';

import 'test_database_factory.dart';

const String foodCategoryId = 'builtin.food-drinks';
const String transportCategoryId = 'builtin.transport';
const String otherCategoryId = 'builtin.other';

Future<ExpenseRepository> openRepository(Directory directory) async {
  final repository = ExpenseRepository(
    factory: createTestDatabaseFactory(),
    storagePolicy: FixedDirectoryStoragePolicy(directory.path),
  );
  final result = await repository.initialize();
  if (result is Failure<void>) {
    throw StateError('Repository initialization failed: ${result.failure}');
  }
  return repository;
}

ImmutableSubmission makeSubmission({
  required String id,
  required String amountText,
  required String categoryId,
  required LocalDate date,
  String? note,
}) {
  final parsed = Money.parse(amountText);
  if (parsed.value == null) {
    throw ArgumentError('Invalid test amount: $amountText');
  }
  return ImmutableSubmission(
    id: ExpenseId(id),
    amount: parsed.value!,
    categoryId: categoryId,
    date: date,
    note: note == null ? null : Note.canonical(note),
  );
}

class FailingStoragePolicy implements LocalStoragePolicy {
  const FailingStoragePolicy();

  @override
  Future<Result<PrivateStoreLocation>> prepareExpenseDirectory() async =>
      const Failure<PrivateStoreLocation>(
        AppFailure(AppFailureCode.privacyPolicyUnavailable),
      );
}
