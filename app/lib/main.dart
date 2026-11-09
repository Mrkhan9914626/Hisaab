import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

import 'app.dart';
import 'core/domain/app_failure.dart';
import 'core/presentation/app_theme.dart';
import 'core/storage/local_storage_policy.dart';
import 'features/record_expenses/application/save_coordinator.dart';
import 'features/record_expenses/data/expense_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerBootstrap());
}

class ExpenseTrackerBootstrap extends StatefulWidget {
  const ExpenseTrackerBootstrap({super.key});

  @override
  State<ExpenseTrackerBootstrap> createState() =>
      _ExpenseTrackerBootstrapState();
}

class _ExpenseTrackerBootstrapState extends State<ExpenseTrackerBootstrap> {
  late final ExpenseRepository _repository;
  late final SaveCoordinator _coordinator;

  bool _initializing = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _repository = ExpenseRepository(
      factory: databaseFactory,
      storagePolicy: const MethodChannelLocalStoragePolicy(),
    );
    _coordinator = SaveCoordinator(_repository);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _failure = null;
      });
    }
    final result = await _repository.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _initializing = false;
      _failure = result is Failure<void> ? result.failure : null;
    });
  }

  @override
  void dispose() {
    unawaited(_repository.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final failure = _failure;
    if (failure != null) {
      return MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: _BootstrapError(failure: failure, onRetry: _initialize),
      );
    }

    return ExpenseTrackerApp(
      repository: _repository,
      coordinator: _coordinator,
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 44,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                failure.userMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => unawaited(onRetry()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
