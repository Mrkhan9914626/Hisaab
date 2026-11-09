import 'dart:io';

import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/presentation/add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  late Directory directory;
  late ExpenseRepository repository;
  late SaveCoordinator coordinator;

  setUp(() async {
    directory = createTempDirectory('add_expense_validation_');
    repository = await openRepository(directory);
    coordinator = SaveCoordinator(repository);
  });

  tearDown(() async {
    await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  Widget host() {
    return MaterialApp(
      theme: AppTheme.light,
      home: AddExpenseScreen(
        repository: repository,
        coordinator: coordinator,
      ),
    );
  }

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  testWidgets('blank and zero amounts show field instructions and preserve input',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount.'), findsOneWidget);
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0.00');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter at least PKR 0.01.'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
  });

  testWidgets('malformed and over-precise amounts are rejected without truncation',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, '1,000');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount like 650.25.'), findsOneWidget);
    expect(find.text('1,000'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1.001');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount like 650.25.'), findsOneWidget);
    expect(find.text('1.001'), findsOneWidget);
  });

  testWidgets('a 201-grapheme note is rejected without truncation',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, '10.00');
    await tester.enterText(find.byType(TextField).last, 'a' * 201);
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Use 200 characters or fewer.'), findsOneWidget);
    expect(find.text('a' * 201), findsOneWidget);
  });
}
