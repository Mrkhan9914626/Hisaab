import 'package:flutter/material.dart';

import 'core/presentation/app_theme.dart';
import 'features/record_expenses/application/save_coordinator.dart';
import 'features/record_expenses/data/expense_repository.dart';
import 'features/record_expenses/presentation/overview_screen.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({
    super.key,
    required this.repository,
    required this.coordinator,
  });

  final ExpenseRepository repository;
  final SaveCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: OverviewScreen(
        repository: repository,
        coordinator: coordinator,
      ),
    );
  }
}
