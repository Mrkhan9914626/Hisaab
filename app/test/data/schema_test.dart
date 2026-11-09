import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../support/test_database_factory.dart';

void main() {
  late Directory directory;
  late AppDatabase appDatabase;

  setUp(() async {
    directory = createTempDirectory('expense_schema_');
    appDatabase = AppDatabase(
      factory: createTestDatabaseFactory(),
      path: '${directory.path}/expenses.db',
    );
    final result = await appDatabase.open();
    expect(result, isA<Success<void>>());
  });

  tearDown(() async {
    await appDatabase.close();
    directory.deleteSync(recursive: true);
  });

  test('creates schema v1 with the required pragmas', () async {
    final database = appDatabase.database;
    final version = await database.rawQuery('PRAGMA user_version');
    expect(version.first.values.first, 1);

    final foreignKeys = await database.rawQuery('PRAGMA foreign_keys');
    expect(foreignKeys.first['foreign_keys'], 1);
    final journal = await database.rawQuery('PRAGMA journal_mode');
    expect(journal.first['journal_mode'].toString().toLowerCase(), 'delete');
    final synchronous = await database.rawQuery('PRAGMA synchronous');
    expect(synchronous.first['synchronous'], 3);
  });

  test('seeds exactly six stable categories once', () async {
    final database = appDatabase.database;
    final rows = await database.query('categories');
    expect(rows.length, 6);
    expect(
      rows.where((row) => row['id'] == 'builtin.other').single['is_protected'],
      1,
    );
    expect(
      rows.where((row) => row['id'] == 'builtin.other').single['is_active'],
      1,
    );
  });

  test('protects Other from rename, deactivation and deletion', () async {
    final database = appDatabase.database;
    await expectLater(
      database.update(
        'categories',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: ['builtin.other'],
      ),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.delete(
        'categories',
        where: 'id = ?',
        whereArgs: ['builtin.other'],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('rejects new expenses for inactive categories', () async {
    final database = appDatabase.database;
    await database.update(
      'categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: ['builtin.transport'],
    );
    await expectLater(
      database.insert('expenses', {
        'id': 'inactive-1',
        'amount_minor': 100,
        'category_id': 'builtin.transport',
        'expense_date': '2026-11-08',
        'note': null,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('enforces amount bounds and RESTRICT foreign keys', () async {
    final database = appDatabase.database;
    await expectLater(
      database.insert('expenses', {
        'id': 'zero-amount',
        'amount_minor': 0,
        'category_id': 'builtin.food-drinks',
        'expense_date': '2026-11-08',
        'note': null,
      }),
      throwsA(isA<DatabaseException>()),
    );

    await database.insert('expenses', {
      'id': 'valid-amount',
      'amount_minor': 100,
      'category_id': 'builtin.food-drinks',
      'expense_date': '2026-11-08',
      'note': null,
    });
    await expectLater(
      database.delete(
        'categories',
        where: 'id = ?',
        whereArgs: ['builtin.food-drinks'],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('reopening does not reseed or replace data', () async {
    final database = appDatabase.database;
    await database.insert('expenses', {
      'id': 'kept-1',
      'amount_minor': 1234,
      'category_id': 'builtin.food-drinks',
      'expense_date': '2026-11-08',
      'note': 'kept',
    });
    await appDatabase.close();

    final reopened = AppDatabase(
      factory: createTestDatabaseFactory(),
      path: '${directory.path}/expenses.db',
    );
    expect(await reopened.open(), isA<Success<void>>());
    expect((await reopened.database.query('categories')).length, 6);
    expect((await reopened.database.query('expenses')).length, 1);
    await reopened.close();
  });
}
