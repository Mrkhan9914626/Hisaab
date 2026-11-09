import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/presentation/category_icon.dart';
import '../../../core/presentation/date_format.dart';
import '../../../core/presentation/money_text.dart';
import '../../../core/presentation/storage_notice.dart';
import '../application/overview_controller.dart';
import '../application/save_coordinator.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';
import '../domain/overview_snapshot.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.repository,
    required this.coordinator,
  });

  final ExpenseRepository repository;
  final SaveCoordinator coordinator;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with WidgetsBindingObserver {
  late final OverviewController _controller;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _controller = OverviewController(repository: widget.repository);
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightReload();
    unawaited(_controller.load());
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleMidnightReload() {
    if (!mounted) {
      return;
    }
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextDay.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) {
          return;
        }
        unawaited(_controller.load());
        _scheduleMidnightReload();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.load());
      _scheduleMidnightReload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AddExpenseScreen(
          repository: widget.repository,
          coordinator: widget.coordinator,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _controller.load();
    }
  }

  Future<void> _openDetails(Expense expense) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ExpenseDetailsScreen(
          repository: widget.repository,
          expenseId: expense.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
        tooltip: 'Add expense',
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.status) {
      case OverviewStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading spending…'),
            ],
          ),
        );
      case OverviewStatus.unavailable:
        return _ErrorState(
          message: _controller.failure?.userMessage ??
              'Saved data is unavailable right now.',
          onRetry: _controller.load,
        );
      case OverviewStatus.emptyEver:
      case OverviewStatus.emptyToday:
      case OverviewStatus.available:
      case OverviewStatus.stale:
        final snapshot = _controller.snapshot;
        if (snapshot == null) {
          return _ErrorState(
            message: _controller.failure?.userMessage ??
                'Saved data is unavailable right now.',
            onRetry: _controller.load,
          );
        }
        return _snapshotBody(context, snapshot);
    }
  }

  Widget _snapshotBody(BuildContext context, OverviewSnapshot snapshot) {
    final theme = Theme.of(context);
    final isStale = _controller.status == OverviewStatus.stale;
    final rows = snapshot.todayRows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        if (isStale) ...[
          _StaleBanner(
            message: _controller.failure?.userMessage ??
                'Showing the last loaded totals. Refresh failed.',
            onRetry: _controller.load,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          formatCivilDate(snapshot.today),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text(
                        MoneyText.formatMinor(snapshot.todayTotalMinor),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _countLabel(snapshot.todayCount),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_controller.status == OverviewStatus.emptyEver)
          _EmptyEver(onAdd: _openAdd)
        else if (_controller.status == OverviewStatus.emptyToday)
          const _EmptyToday()
        else if (rows.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _ExpenseRow(
                    expense: rows[index],
                    onTap: () => _openDetails(rows[index]),
                  ),
                  if (index != rows.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text('This month', style: theme.textTheme.labelLarge),
                ),
                Text(
                  MoneyText.formatMinor(snapshot.monthTotalMinor),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const StorageNotice(),
      ],
    );
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 expense' : '$count expenses';
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('expense_${expense.id.value}'),
      leading: CircleAvatar(
        child: Icon(iconForCategory(expense.category.iconKey)),
      ),
      title: Text(expense.category.name),
      subtitle: Text(expense.note?.text ?? expense.category.name),
      trailing: Text(
        MoneyText.format(expense.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}

class _EmptyEver extends StatelessWidget {
  const _EmptyEver({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No expenses yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Record what you spend today. Amounts, categories and totals '
              'stay on this device and work without a connection.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No expenses today', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Earlier records are still saved. Your current-month total '
              'stays above.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
              Icons.storage_outlined,
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
            FilledButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
