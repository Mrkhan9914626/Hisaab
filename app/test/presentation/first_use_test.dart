import 'dart:io';

import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:expense_tracker/features/record_expenses/application/save_coordinator.dart';
import 'package:expense_tracker/features/record_expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/record_expenses/presentation/overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic_fixtures.dart';

void main() {
  testWidgets('first use shows zero spending, explanation and disclosure',
      (tester) async {
    final directory = createTempDirectory('first_use_');
    final repository = await openRepository(directory);
    final coordinator = SaveCoordinator(repository);
    addTearDown(() async {
      await repository.dispose();
      directory.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OverviewScreen(
          repository: repository,
          coordinator: coordinator,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Add your first expense'), findsOneWidget);
    expect(find.text('PKR 0.00'), findsWidgets);
    expect(find.textContaining('Records stay only on this device'),
        findsOneWidget);
    expect(find.textContaining('no recovery'), findsOneWidget);
    expect(find.text('Add expense'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
