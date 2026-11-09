import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = createTempDirectory('expense_init_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('initializes an empty store and exposes six active categories', () async {
    final repository = await openRepository(directory);
    final categories = await repository.listActiveCategories();
    expect(categories.valueOrNull, isNotNull);
    expect(categories.valueOrNull!.map((category) => category.name), [
      'Food & drinks',
      'Transport',
      'Shopping',
      'Bills',
      'Health',
      'Other',
    ]);
    await repository.dispose();
  });

  test('reopening preserves identities and does not reseed', () async {
    final first = await openRepository(directory);
    final firstIds = (await first.listActiveCategories())
        .valueOrNull!
        .map((category) => category.id)
        .toList();
    await first.dispose();

    final second = await openRepository(directory);
    final secondIds = (await second.listActiveCategories())
        .valueOrNull!
        .map((category) => category.id)
        .toList();
    expect(secondIds, firstIds);
    await second.dispose();
  });

  test('privacy policy failure blocks initialization without fallback', () async {
    final repository = ExpenseRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: const FailingStoragePolicy(),
    );
    final result = await repository.initialize();
    expect(result, isA<Failure<void>>());
    expect(
      (result as Failure<void>).failure.code,
      AppFailureCode.privacyPolicyUnavailable,
    );
    expect(repository.isInitialized, isFalse);
  });

  test('an existing corrupt file is an error, not a reset', () async {
    File('${directory.path}/${ExpenseRepository.databaseFileName}')
        .writeAsStringSync('this is not a sqlite database');

    final repository = ExpenseRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(directory.path),
    );
    final result = await repository.initialize();
    expect(result, isA<Failure<void>>());
    expect(repository.isInitialized, isFalse);
  });
}
