import 'package:sqflite/sqflite.dart';

import '../domain/app_failure.dart';
import 'migrations.dart';

class _IncompatibleStore implements Exception {
  const _IncompatibleStore();
}

class _UnexpectedStoreVersion implements Exception {
  const _UnexpectedStoreVersion();
}

/// Owns one SQLite connection and the schema lifecycle.
class AppDatabase {
  AppDatabase({required this.factory, required this.path});

  static const int schemaVersion = 1;
  static const int recoveryAttempts = 3;
  static const Duration closeTimeout = Duration(seconds: 5);
  static const Duration recoveryTimeout = Duration(seconds: 8);

  final DatabaseFactory factory;
  final String path;

  Database? _database;

  Database get database {
    final database = _database;
    if (database == null) {
      throw StateError('Database has not been opened');
    }
    return database;
  }

  bool get isOpen => _database != null;

  Future<Result<void>> open() async {
    try {
      final database = await factory.openDatabase(
        path,
        options: _openOptions(),
      );
      _database = database;

      final pragmaFailure = await _verifyPragmas(database);
      if (pragmaFailure != null) {
        await close();
        return Failure<void>(pragmaFailure);
      }

      final invariantFailure = await _verifyInvariants(database);
      if (invariantFailure != null) {
        await close();
        return Failure<void>(invariantFailure);
      }

      return const Success<void>(null);
    } on _IncompatibleStore {
      await close();
      return const Failure<void>(
        AppFailure(AppFailureCode.incompatibleStore),
      );
    } on _UnexpectedStoreVersion {
      await close();
      return const Failure<void>(
        AppFailure(AppFailureCode.initializationFailed),
      );
    } catch (_) {
      await close();
      return const Failure<void>(
        AppFailure(AppFailureCode.initializationFailed),
      );
    }
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) {
      await database.close();
    }
  }

  /// Prevents any further use of the possibly tainted handle. The close future
  /// is bounded, but the handle is never reused even if it does not settle in
  /// time.
  Future<void> quarantine() async {
    final database = _database;
    _database = null;
    if (database == null) {
      return;
    }
    try {
      await database.close().timeout(closeTimeout);
    } catch (_) {
      // Recovery opens a fresh connection and proves a writer boundary.
    }
  }

  /// Reopens the same file and runs [action] inside a transaction that first
  /// performs a harmless write. Acquiring that writer lock drains any pending
  /// native writer, and reading through the same transaction observes the
  /// committed state rather than an old uncommitted view.
  Future<Result<T>> recoverWithWriterFence<T>(
    Future<Result<T>> Function(DatabaseExecutor executor) action,
  ) async {
    await quarantine();

    for (var attempt = 0; attempt < recoveryAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
      }

      Database? recovered;
      try {
        final exists =
            await factory.databaseExists(path).timeout(recoveryTimeout);
        if (!exists) {
          continue;
        }

        recovered = await factory
            .openDatabase(path, options: _openOptions())
            .timeout(recoveryTimeout);

        final pragmaFailure = await _verifyPragmas(recovered);
        if (pragmaFailure != null) {
          await _closeQuietly(recovered);
          continue;
        }

        final invariantFailure = await _verifyInvariants(recovered);
        if (invariantFailure != null) {
          await _closeQuietly(recovered);
          continue;
        }

        final result = await recovered.transaction<Result<T>>(
          (transaction) async {
            await transaction.rawUpdate(
              "UPDATE categories SET is_active = is_active "
              "WHERE id = 'builtin.other'",
            );
            return action(transaction);
          },
        ).timeout(recoveryTimeout);

        _database = recovered;
        return result;
      } catch (_) {
        if (recovered != null) {
          await _closeQuietly(recovered);
        }
      }
    }

    return Failure<T>(
      const AppFailure(
        AppFailureCode.outcomeUnavailable,
        retryKind: RetryKind.reconciliation,
      ),
    );
  }

  OpenDatabaseOptions _openOptions() => OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _configure,
        onCreate: (database, version) => createSchemaV1(database),
        onUpgrade: (database, oldVersion, newVersion) async {
          throw const _UnexpectedStoreVersion();
        },
        onDowngrade: (database, oldVersion, newVersion) async {
          throw const _IncompatibleStore();
        },
      );

  static Future<void> _closeQuietly(Database database) async {
    try {
      await database.close().timeout(closeTimeout);
    } catch (_) {
      // A fresh recovery attempt uses a new connection; this handle is dropped.
    }
  }

  static Future<void> _configure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
    await database.rawQuery('PRAGMA journal_mode = DELETE');
    await database.rawQuery('PRAGMA synchronous = EXTRA');
  }

  Future<AppFailure?> _verifyPragmas(Database database) async {
    final foreignKeys = await database.rawQuery('PRAGMA foreign_keys');
    final journalMode = await database.rawQuery('PRAGMA journal_mode');
    final synchronous = await database.rawQuery('PRAGMA synchronous');

    final foreignKeysEnabled = foreignKeys.isNotEmpty &&
        foreignKeys.first['foreign_keys'] == 1;
    final journal = journalMode.isEmpty
        ? ''
        : (journalMode.first['journal_mode'] ?? '').toString().toLowerCase();
    final syncLevel =
        synchronous.isEmpty ? null : synchronous.first['synchronous'];

    if (!foreignKeysEnabled || journal != 'delete' || syncLevel != 3) {
      return const AppFailure(AppFailureCode.storageUnavailable);
    }
    return null;
  }

  Future<AppFailure?> _verifyInvariants(Database database) async {
    final rows = await database.rawQuery(
      'SELECT id, name, is_active, is_protected FROM categories',
    );
    final byId = <String, Map<String, Object?>>{
      for (final row in rows) row['id'] as String: row,
    };

    for (final seed in seedCategories) {
      if (!byId.containsKey(seed['id'])) {
        return const AppFailure(AppFailureCode.integrityFailure);
      }
    }

    final other = byId['builtin.other'];
    if (other == null ||
        other['name'] != 'Other' ||
        other['is_active'] != 1 ||
        other['is_protected'] != 1) {
      return const AppFailure(AppFailureCode.integrityFailure);
    }

    final hasActiveCategory = rows.any((row) => row['is_active'] == 1);
    if (!hasActiveCategory) {
      return const AppFailure(AppFailureCode.integrityFailure);
    }

    return null;
  }
}
