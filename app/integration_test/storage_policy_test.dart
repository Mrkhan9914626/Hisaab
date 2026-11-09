import 'dart:io';

import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native policy returns a verified private no-backup directory',
      (tester) async {
    const policy = MethodChannelLocalStoragePolicy();
    final result = await policy.prepareExpenseDirectory();
    expect(result.valueOrNull, isNotNull);

    final path = result.valueOrNull!.directoryPath;
    expect(path.trim(), isNotEmpty);
    expect(path.toLowerCase().contains('cache'), isFalse);

    final probe = Directory('$path/integration_probe');
    if (!probe.existsSync()) {
      probe.createSync(recursive: true);
    }

    final repository = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: FixedDirectoryStoragePolicy(probe.path),
    );
    expect(await repository.initialize(), isA<Success<void>>());
    expect(
      (await repository.listActiveCategories()).valueOrNull?.length,
      6,
    );
    await repository.dispose();
    probe.deleteSync(recursive: true);
  });
}
