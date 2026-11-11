import 'package:flutter/material.dart';

import '../../../core/domain/app_failure.dart';

/// Distinct, non-interchangeable empty and failure bodies for History.
class HistoryStates extends StatelessWidget {
  const HistoryStates({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const <Widget>[],
  });

  factory HistoryStates.emptyPeriod({
    required VoidCallback onGoToToday,
    VoidCallback? onAddForSelectedDay,
  }) {
    return HistoryStates(
      icon: Icons.event_busy_outlined,
      title: 'This period is empty',
      message: 'No expenses are saved for the selected period. '
          'Earlier or later records are still available.',
      actions: <Widget>[
        if (onAddForSelectedDay != null)
          FilledButton.icon(
            onPressed: onAddForSelectedDay,
            icon: const Icon(Icons.add),
            label: const Text('Add expense for this day'),
          ),
        OutlinedButton(
          onPressed: onGoToToday,
          child: const Text('Go to today'),
        ),
      ],
    );
  }

  factory HistoryStates.noFilterMatches({
    required VoidCallback onClearFilter,
  }) {
    return HistoryStates(
      icon: Icons.filter_alt_off_outlined,
      title: 'No entries match this filter',
      message: 'No expenses in the selected period match the active category '
          'filter. Clear the filter to see the full period.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: onClearFilter,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Clear filter'),
        ),
      ],
    );
  }

  factory HistoryStates.emptyEver({required VoidCallback onAdd}) {
    return HistoryStates(
      icon: Icons.receipt_long_outlined,
      title: 'No expenses yet',
      message: 'Record your first expense. Amounts, categories and totals stay '
          'on this device and work without a connection.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add your first expense'),
        ),
      ],
    );
  }

  factory HistoryStates.unavailable({
    required AppFailure? failure,
    required VoidCallback onRetry,
  }) {
    return HistoryStates(
      icon: Icons.storage_outlined,
      title: 'History is unavailable',
      message: failure?.userMessage ??
          'Saved data is unavailable right now. Try again.',
      actions: <Widget>[
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 44,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner that marks retained values as stale after a failed refresh.
class HistoryStaleBanner extends StatelessWidget {
  const HistoryStaleBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing last loaded values. $message',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
