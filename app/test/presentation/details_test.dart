import 'dart:io';

import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:expense_tracker/features/record_expenses/presentation/expense_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  testWidgets('shows read-only details with note fallback and no edit/delete',
      (tester) async {
    final directory = createTempDirectory('details_widget_');
    final repository = await openRepository(directory);
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });

    await repository.createExpense(
      makeSubmission(
        id: 'details-widget-1',
        amountText: '12.34',
        categoryId: foodCategoryId,
        date: LocalDate(2026, 11, 8),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ExpenseDetailsScreen(
          repository: repository,
          expenseId: const ExpenseId('details-widget-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PKR 12.34'), findsOneWidget);
    expect(find.text('Food & drinks'), findsOneWidget);
    expect(find.text('No note added'), findsOneWidget);
    expect(find.textContaining('Stored only on this device'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });
}
