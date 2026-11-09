import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/application/overview_controller.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/overview_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

class _FlakyOverviewRepository extends ExpenseRepository {
  _FlakyOverviewRepository({
    required super.factory,
    required super.storagePolicy,
  });

  bool fail = false;

  @override
  Future<Result<OverviewSnapshot>> loadOverview(LocalDate today) {
    if (fail) {
      return Future.value(
        const Failure<OverviewSnapshot>(
          AppFailure(AppFailureCode.storageUnavailable),
        ),
      );
    }
    return super.loadOverview(today);
  }
}

void main() {
  final today = LocalDate(2026, 11, 8);

  late Directory directory;
  late ExpenseRepository repository;

  setUp(() async {
    directory = createTempDirectory('overview_states_');
    repository = await openRepository(directory);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('empty store is emptyEver, never unavailable', () async {
    final controller = OverviewController(
      repository: repository,
      clock: () => today,
    );
    await controller.load();
    expect(controller.status, OverviewStatus.emptyEver);
    expect(controller.snapshot!.hasAnyExpenses, isFalse);
  });

  test('earlier history with no expenses today is emptyToday', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'earlier-state-1',
        amountText: '50.05',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 11, 5),
      ),
    );
    final controller = OverviewController(
      repository: repository,
      clock: () => today,
    );
    await controller.load();
    expect(controller.status, OverviewStatus.emptyToday);
    expect(controller.snapshot!.todayCount, 0);
    expect(controller.snapshot!.monthTotalMinor, 5005);
    expect(controller.snapshot!.hasAnyExpenses, isTrue);
  });

  test('today rows produce the available state', () async {
    await repository.createExpense(
      makeSubmission(
        id: 'today-state-1',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    final controller = OverviewController(
      repository: repository,
      clock: () => today,
    );
    await controller.load();
    expect(controller.status, OverviewStatus.available);
    expect(controller.snapshot!.todayCount, 1);
  });

  test('a failed first read is unavailable, not empty', () async {
    final flakyDirectory = createTempDirectory('overview_flaky_');
    final flaky = _FlakyOverviewRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(flakyDirectory.path),
    );
    addTearDown(() async {
      await flaky.dispose();
      flakyDirectory.deleteSync(recursive: true);
    });
    await flaky.initialize();
    flaky.fail = true;

    final controller = OverviewController(
      repository: flaky,
      clock: () => today,
    );
    await controller.load();
    expect(controller.status, OverviewStatus.unavailable);
    expect(controller.snapshot, isNull);
  });

  test('a failed refresh retains prior values but marks them stale', () async {
    final flakyDirectory = createTempDirectory('overview_flaky_stale_');
    final flaky = _FlakyOverviewRepository(
      factory: createTestDatabaseFactory(),
      storagePolicy: FixedDirectoryStoragePolicy(flakyDirectory.path),
    );
    addTearDown(() async {
      await flaky.dispose();
      flakyDirectory.deleteSync(recursive: true);
    });
    await flaky.initialize();

    final controller = OverviewController(
      repository: flaky,
      clock: () => today,
    );
    await controller.load();
    expect(controller.status, OverviewStatus.emptyEver);

    flaky.fail = true;
    await controller.load();
    expect(controller.status, OverviewStatus.stale);
    expect(controller.snapshot, isNotNull);
    expect(controller.failure, isNotNull);
  });
}
