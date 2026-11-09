import 'dart:io';

import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../support/synthetic_fixtures.dart';
import '../support/test_database_factory.dart';

void main() {
  late Directory directory;
  final today = LocalDate(2026, 11, 8);

  setUp(() {
    directory = createTempDirectory('categories_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('seeds six stable ids, names and icons', () async {
    final repository = await openRepository(directory);
    final categories = (await repository.listActiveCategories()).valueOrNull!;
    expect(categories.map((category) => category.id), [
      'builtin.food-drinks',
      'builtin.transport',
      'builtin.shopping',
      'builtin.bills',
      'builtin.health',
      'builtin.other',
    ]);
    expect(categories.map((category) => category.name), [
      'Food & drinks',
      'Transport',
      'Shopping',
      'Bills',
      'Health',
      'Other',
    ]);
    expect(categories.map((category) => category.iconKey), [
      'food_drinks',
      'transport',
      'shopping',
      'bills',
      'health',
      'other',
    ]);
    final other = categories.singleWhere((category) => category.id == otherCategoryId);
    expect(other.isProtected, isTrue);
    expect(other.isActive, isTrue);
    await repository.dispose();
  });

  test('archived categories leave active choices but stay readable',
      () async {
    final repository = await openRepository(directory);
    await repository.createExpense(
      makeSubmission(
        id: 'archived-category-row',
        amountText: '10.00',
        categoryId: transportCategoryId,
        date: today,
      ),
    );

    final admin = await repository.factory.openDatabase(
      '${directory.path}/${ExpenseRepository.databaseFileName}',
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await admin.update(
      'categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [transportCategoryId],
    );
    await admin.close();

    final active = (await repository.listActiveCategories()).valueOrNull!;
    expect(active.map((category) => category.id), isNot(contains(transportCategoryId)));

    final saved =
        (await repository.loadExpense(const ExpenseId('archived-category-row')))
            .valueOrNull!;
    expect(saved.category.name, 'Transport');
    expect(saved.category.isActive, isFalse);
    await repository.dispose();
  });

  test('repeated opens neither duplicate nor replace category rows',
      () async {
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
    expect(secondIds.length, 6);
    await second.dispose();
  });
}
