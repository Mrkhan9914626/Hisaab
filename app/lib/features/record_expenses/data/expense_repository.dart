import 'package:sqflite/sqflite.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/domain/money.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/local_storage_policy.dart';
import '../../browse_history/domain/category_filter.dart';
import '../../browse_history/domain/history_snapshot.dart';
import '../domain/category.dart';
import '../domain/expense.dart';
import '../domain/overview_snapshot.dart';
import '../domain/submission.dart';
import 'write_cancellation.dart';

class ExpenseRepository {
  ExpenseRepository({
    required this.factory,
    required this.storagePolicy,
  });

  static const String databaseFileName = 'expenses.db';

  final DatabaseFactory factory;
  final LocalStoragePolicy storagePolicy;

  AppDatabase? _store;
  String? _databasePath;

  bool get isInitialized => _store?.isOpen ?? false;

  Database get _database {
    final store = _store;
    if (store == null) {
      throw StateError('ExpenseRepository.initialize must be awaited first');
    }
    return store.database;
  }

  Future<Result<void>> initialize() async {
    final existing = _store;
    if (existing != null) {
      if (existing.isOpen) {
        return const Success<void>(null);
      }
      return const Failure<void>(
        AppFailure(
          AppFailureCode.outcomeUnavailable,
          retryKind: RetryKind.reconciliation,
        ),
      );
    }

    final locationResult = await storagePolicy.prepareExpenseDirectory();
    switch (locationResult) {
      case Failure<PrivateStoreLocation>(:final failure):
        return Failure<void>(failure);
      case Success<PrivateStoreLocation>(:final value):
        final path = '${value.directoryPath}/$databaseFileName';
        final store = AppDatabase(factory: factory, path: path);
        final openResult = await store.open();
        switch (openResult) {
          case Failure<void>(:final failure):
            return Failure<void>(failure);
          case Success<void>():
            _store = store;
            _databasePath = path;
            return const Success<void>(null);
        }
    }
  }

  Future<void> dispose() async {
    final store = _store;
    _store = null;
    _databasePath = null;
    await store?.close();
  }

  Future<void> quarantineAfterUncertainWrite() async {
    await _store?.quarantine();
  }

  Future<Result<Expense?>> recoverAndFind(ExpenseId id) async {
    final path = _databasePath;
    if (path == null) {
      return const Failure<Expense?>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }

    final store = _store ?? AppDatabase(factory: factory, path: path);
    _store = store;

    try {
      return await store.recoverWithWriterFence<Expense?>((executor) async {
        final expense = await _readExpenseById(executor, id);
        return Success<Expense?>(expense);
      });
    } catch (_) {
      return const Failure<Expense?>(
        AppFailure(
          AppFailureCode.outcomeUnavailable,
          retryKind: RetryKind.reconciliation,
        ),
      );
    }
  }

  Future<Result<List<Category>>> listActiveCategories() async {
    try {
      final rows = await _database.rawQuery(
        'SELECT id, name, icon_key, is_active, is_protected '
        'FROM categories WHERE is_active = 1 ORDER BY rowid',
      );
      return Success(
        rows.map(_categoryFromRow).toList(growable: false),
      );
    } catch (_) {
      return const Failure<List<Category>>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
  }

  Future<Result<List<Category>>> listCategoriesForFilter() async {
    try {
      final rows = await _database.rawQuery(
        'SELECT id, name, icon_key, is_active, is_protected '
        'FROM categories ORDER BY rowid',
      );
      return Success(
        rows.map(_categoryFromRow).toList(growable: false),
      );
    } catch (_) {
      return const Failure<List<Category>>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
  }

  Future<Result<Expense>> createExpense(
    ImmutableSubmission submission, {
    WriteCancellation? cancellation,
  }) async {
    final Database database;
    try {
      database = _database;
    } catch (_) {
      return const Failure<Expense>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }

    try {
      return await database.transaction<Result<Expense>>((transaction) async {
        final existing = await _readExpenseById(transaction, submission.id);
        if (existing != null) {
          if (existing.matchesSubmission(submission)) {
            return Success(existing);
          }
          return const Failure<Expense>(
            AppFailure(AppFailureCode.integrityFailure),
          );
        }

        final category = await _readCategory(transaction, submission.categoryId);
        if (category == null || !category.isActive) {
          return const Failure<Expense>(
            AppFailure(AppFailureCode.integrityFailure),
          );
        }

        if (cancellation?.isCancelled ?? false) {
          throw const CancellationRollback();
        }

        final saveSequence = await transaction.rawInsert(
          'INSERT INTO expenses '
          '(id, amount_minor, category_id, expense_date, note) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            submission.id.value,
            submission.amount.minorUnits,
            submission.categoryId,
            submission.date.iso,
            submission.note?.text,
          ],
        );

        if (cancellation?.isCancelled ?? false) {
          throw const CancellationRollback();
        }

        return Success(
          Expense(
            id: submission.id,
            saveSequence: saveSequence,
            amount: submission.amount,
            category: category,
            date: submission.date,
            note: submission.note,
          ),
        );
      });
    } on CancellationRollback {
      rethrow;
    } catch (_) {
      throw const UncertainWriteException();
    }
  }

  Future<Result<OverviewSnapshot>> loadOverview(LocalDate today) async {
    try {
      final database = _database;
      return await database.transaction<Result<OverviewSnapshot>>(
        (transaction) async {
          final todayRows = (await transaction.rawQuery(
            '$_selectExpenseWithCategory WHERE e.expense_date = ? '
            'ORDER BY e.save_sequence DESC',
            [today.iso],
          ))
              .map(_expenseFromRow)
              .toList(growable: false);

          final monthStart = today.firstOfMonth;
          final nextMonthStart = monthStart.nextMonthStart;
          final monthSumRows = nextMonthStart == null
              ? await transaction.rawQuery(
                  'SELECT SUM(amount_minor) AS total FROM expenses '
                  'WHERE expense_date >= ? AND expense_date <= ?',
                  [monthStart.iso, '9999-12-31'],
                )
              : await transaction.rawQuery(
                  'SELECT SUM(amount_minor) AS total FROM expenses '
                  'WHERE expense_date >= ? AND expense_date < ?',
                  [monthStart.iso, nextMonthStart.iso],
                );

          final anyRows = await transaction.rawQuery(
            'SELECT EXISTS(SELECT 1 FROM expenses) AS present',
          );
          final hasAnyExpenses = anyRows.isNotEmpty &&
              anyRows.first['present'] == 1;

          final todayTotal = _checkedTotal(
            todayRows.map((expense) => expense.amount.minorUnits),
          );
          if (todayTotal.failure != null) {
            return Failure<OverviewSnapshot>(todayTotal.failure!);
          }

          final monthValue = monthSumRows.first['total'];
          final int monthTotalMinor;
          if (monthValue == null) {
            monthTotalMinor = 0;
          } else if (monthValue is int) {
            monthTotalMinor = monthValue;
          } else {
            return const Failure<OverviewSnapshot>(
              AppFailure(AppFailureCode.calculationOverflow),
            );
          }
          final monthTotal = _checkedTotal([monthTotalMinor]);
          if (monthTotal.failure != null) {
            return Failure<OverviewSnapshot>(monthTotal.failure!);
          }

          return Success(
            OverviewSnapshot(
              today: today,
              todayRows: todayRows,
              todayCount: todayRows.length,
              todayTotalMinor: todayTotal.value!,
              monthTotalMinor: monthTotal.value!,
              hasAnyExpenses: hasAnyExpenses,
            ),
          );
        },
      );
    } catch (error) {
      if (error.toString().toLowerCase().contains('overflow')) {
        return const Failure<OverviewSnapshot>(
          AppFailure(AppFailureCode.calculationOverflow),
        );
      }
      return const Failure<OverviewSnapshot>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
  }

  Future<Result<HistorySnapshot>> loadHistory(HistoryQuery query) async {
    final Database database;
    try {
      database = _database;
    } catch (_) {
      return const Failure<HistorySnapshot>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }

    try {
      return await database.transaction<Result<HistorySnapshot>>(
        (transaction) async {
          final where = StringBuffer(
            'WHERE e.expense_date >= ? AND e.expense_date <= ?',
          );
          final arguments = <Object?>[
            query.period.start.iso,
            query.period.end.iso,
          ];
          final filter = query.filter;
          if (filter is SelectedCategory) {
            where.write(' AND e.category_id = ?');
            arguments.add(filter.categoryId);
          }

          final rows = (await transaction.rawQuery(
            '$_selectExpenseWithCategory $where '
            'ORDER BY e.expense_date DESC, e.save_sequence DESC',
            arguments,
          ))
              .map(_expenseFromRow)
              .toList(growable: false);

          final anyRows = await transaction.rawQuery(
            'SELECT EXISTS(SELECT 1 FROM expenses) AS present',
          );
          final hasAnyExpenses = anyRows.isNotEmpty &&
              anyRows.first['present'] == 1;

          final latestRows = await transaction.rawQuery(
            'SELECT MAX(expense_date) AS latest FROM expenses',
          );
          final latestValue =
              latestRows.isEmpty ? null : latestRows.first['latest'];
          LocalDate? latestExpenseDate;
          if (latestValue is String) {
            latestExpenseDate = LocalDate.tryParse(latestValue);
            if (latestExpenseDate == null) {
              return const Failure<HistorySnapshot>(
                AppFailure(AppFailureCode.integrityFailure),
              );
            }
          }

          return HistorySnapshot.derive(
            period: query.period,
            filter: query.filter,
            rows: rows,
            hasAnyExpenses: hasAnyExpenses,
            latestExpenseDate: latestExpenseDate,
          );
        },
      );
    } catch (error) {
      if (error.toString().toLowerCase().contains('overflow')) {
        return const Failure<HistorySnapshot>(
          AppFailure(AppFailureCode.calculationOverflow),
        );
      }
      return const Failure<HistorySnapshot>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
  }

  Future<Result<Expense>> loadExpense(ExpenseId id) async {
    try {
      final expense = await _readExpenseById(_database, id);
      if (expense == null) {
        return const Failure<Expense>(
          AppFailure(AppFailureCode.integrityFailure),
        );
      }
      return Success(expense);
    } catch (_) {
      return const Failure<Expense>(
        AppFailure(AppFailureCode.storageUnavailable),
      );
    }
  }

  static const String _selectExpenseWithCategory = '''
    SELECT e.save_sequence, e.id, e.amount_minor, e.category_id,
           e.expense_date, e.note,
           c.name AS category_name, c.icon_key,
           c.is_active, c.is_protected
    FROM expenses e
    JOIN categories c ON c.id = e.category_id
  ''';

  Future<Expense?> _readExpenseById(
    DatabaseExecutor executor,
    ExpenseId id,
  ) async {
    final rows = await executor.rawQuery(
      '$_selectExpenseWithCategory WHERE e.id = ?',
      [id.value],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _expenseFromRow(rows.first);
  }

  Future<Category?> _readCategory(
    DatabaseExecutor executor,
    String id,
  ) async {
    final rows = await executor.rawQuery(
      'SELECT id, name, icon_key, is_active, is_protected '
      'FROM categories WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _categoryFromRow(rows.first);
  }

  static Category _categoryFromRow(Map<String, Object?> row) => Category(
        id: row['id'] as String,
        name: row['name'] as String,
        iconKey: row['icon_key'] as String,
        isActive: row['is_active'] == 1,
        isProtected: row['is_protected'] == 1,
      );

  static Expense _expenseFromRow(Map<String, Object?> row) {
    final date = LocalDate.tryParse(row['expense_date'] as String);
    if (date == null) {
      throw const FormatException('Stored expense date is invalid');
    }
    final noteText = row['note'] as String?;
    return Expense(
      id: ExpenseId(row['id'] as String),
      saveSequence: row['save_sequence'] as int,
      amount: Money.fromMinorUnits(row['amount_minor'] as int),
      category: Category(
        id: row['category_id'] as String,
        name: row['category_name'] as String,
        iconKey: row['icon_key'] as String,
        isActive: row['is_active'] == 1,
        isProtected: row['is_protected'] == 1,
      ),
      date: date,
      note: noteText == null ? null : Note.persisted(noteText),
    );
  }

  static final BigInt _maxInt64 = BigInt.parse('9223372036854775807');
  static final BigInt _minInt64 = BigInt.parse('-9223372036854775808');

  static ({int? value, AppFailure? failure}) _checkedTotal(
    Iterable<int> values,
  ) {
    var total = BigInt.zero;
    for (final value in values) {
      total += BigInt.from(value);
    }
    if (total > _maxInt64 || total < _minInt64) {
      return (
        value: null,
        failure: const AppFailure(AppFailureCode.calculationOverflow),
      );
    }
    return (value: total.toInt(), failure: null);
  }
}
