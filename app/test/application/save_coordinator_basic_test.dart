import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  late Directory directory;
  late ExpenseRepository repository;
  late SaveCoordinator coordinator;
  final today = LocalDate(2026, 11, 8);

  setUp(() async {
    directory = createTempDirectory('coordinator_basic_');
    repository = await openRepository(directory);
    coordinator = SaveCoordinator(repository);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test('repeated begin with the same ID and payload attaches', () async {
    final submission = makeSubmission(
      id: 'attached-1',
      amountText: '650.25',
      categoryId: foodCategoryId,
      date: today,
      note: 'Lunch',
    );

    final first = coordinator.begin(submission);
    final second = coordinator.begin(submission);
    expect(identical(first, second), isTrue);

    final outcome = await first.outcome;
    expect(outcome, isA<Saved>());
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 1);
  });

  test('a fresh ID creates a genuinely separate expense', () async {
    final first = coordinator.begin(
      makeSubmission(
        id: 'fresh-1',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    final second = coordinator.begin(
      makeSubmission(
        id: 'fresh-2',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    expect(await first.outcome, isA<Saved>());
    expect(await second.outcome, isA<Saved>());
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 2);
  });

  test('a conflicting payload for an active ID is rejected', () async {
    final first = coordinator.begin(
      makeSubmission(
        id: 'conflict-1',
        amountText: '10.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    final conflict = coordinator.begin(
      makeSubmission(
        id: 'conflict-1',
        amountText: '11.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );

    final conflictOutcome = await conflict.outcome;
    expect(conflictOutcome, isA<KnownUnsaved>());
    expect(
      (conflictOutcome as KnownUnsaved).failure.code,
      AppFailureCode.integrityFailure,
    );
    expect(await first.outcome, isA<Saved>());
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 1);
  });

  test('a settled successful ID replays Saved without a second write', () async {
    final submission = makeSubmission(
      id: 'settled-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );
    expect(await coordinator.begin(submission).outcome, isA<Saved>());
    expect(await coordinator.begin(submission).outcome, isA<Saved>());
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 1);
  });

  test('a settled successful ID with a different payload is rejected',
      () async {
    final submission = makeSubmission(
      id: 'settled-conflict-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );
    expect(await coordinator.begin(submission).outcome, isA<Saved>());

    final conflict = coordinator.begin(
      makeSubmission(
        id: 'settled-conflict-1',
        amountText: '11.00',
        categoryId: foodCategoryId,
        date: today,
      ),
    );
    expect(await conflict.outcome, isA<KnownUnsaved>());
    expect((await repository.loadOverview(today)).valueOrNull!.todayCount, 1);
  });

  test('reconcile finds a previously committed row', () async {
    final submission = makeSubmission(
      id: 'reconcile-1',
      amountText: '10.00',
      categoryId: foodCategoryId,
      date: today,
    );
    await repository.createExpense(submission);

    final outcome = await coordinator.reconcile(submission.id);
    expect(outcome, isA<Saved>());
    expect((outcome as Saved).expense.id, submission.id);
  });

  test('reconcile of an unknown operation does not claim success', () async {
    final outcome = await coordinator.reconcile(const ExpenseId('unknown'));
    expect(outcome, isA<KnownUnsaved>());
  });
}
