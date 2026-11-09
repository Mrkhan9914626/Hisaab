import 'package:flutter/material.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/presentation/category_icon.dart';
import '../../../core/presentation/date_format.dart';
import '../../../core/presentation/money_text.dart';
import '../../../core/presentation/storage_notice.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';
import '../domain/submission.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.repository,
    required this.expenseId,
  });

  final ExpenseRepository repository;
  final ExpenseId expenseId;

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  late Future<Result<Expense>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadExpense(widget.expenseId);
  }

  void _retry() {
    setState(() {
      _future = widget.repository.loadExpense(widget.expenseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<Result<Expense>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final result = snapshot.data;
            if (result is Success<Expense>) {
              return _DetailsBody(expense: result.value);
            }
            final failure = result is Failure<Expense>
                ? result.failure
                : const AppFailure(AppFailureCode.storageUnavailable);
            return _DetailsError(message: failure.userMessage, onRetry: _retry);
          },
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MoneyText.format(expense.amount),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      child: Icon(iconForCategory(expense.category.iconKey)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expense.category.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Date: ${formatCivilDate(expense.date)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  expense.note?.text ?? 'No note added',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const StorageNotice(compact: true),
      ],
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
