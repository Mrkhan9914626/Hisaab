import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/presentation/date_format.dart';
import '../../../core/presentation/money_text.dart';
import '../../../core/presentation/storage_notice.dart';
import '../../record_expenses/application/save_coordinator.dart';
import '../../record_expenses/data/expense_repository.dart';
import '../../record_expenses/domain/expense.dart';
import '../../record_expenses/presentation/add_expense_screen.dart';
import '../../record_expenses/presentation/expense_details_screen.dart';
import '../../record_expenses/presentation/expense_list_row.dart';
import '../application/history_controller.dart';
import '../domain/category_filter.dart';
import '../domain/history_range.dart';
import '../domain/history_snapshot.dart';
import 'history_filter_control.dart';
import 'history_range_controls.dart';
import 'history_states.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    required this.coordinator,
  });

  final ExpenseRepository repository;
  final SaveCoordinator coordinator;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(repository: widget.repository);
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.initialize());
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
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

  Future<void> _openAdd() async {
    final period = _controller.period;
    final filter = _controller.filter;
    final initialDate = _controller.rangeType == HistoryRangeType.day
        ? _controller.anchorDate
        : null;
    final saved = await Navigator.of(context).push<Expense>(
      MaterialPageRoute<Expense>(
        builder: (context) => AddExpenseScreen(
          repository: widget.repository,
          coordinator: widget.coordinator,
          initialDate: initialDate,
        ),
      ),
    );
    if (!mounted || saved == null) {
      return;
    }
    await _controller.refresh();
    if (!mounted) {
      return;
    }
    final inPeriod = period.contains(saved.date);
    final inFilter = switch (filter) {
      AllCategories() => true,
      SelectedCategory(:final categoryId) => categoryId == saved.category.id,
    };
    final refreshed = _controller.status == HistoryStatus.available ||
        _controller.status == HistoryStatus.emptyPeriod ||
        _controller.status == HistoryStatus.noFilterMatches ||
        _controller.status == HistoryStatus.emptyEver;
    final message = !refreshed
        ? 'Expense saved. The view could not be refreshed; retry to see the latest totals.'
        : inPeriod && inFilter
            ? 'Expense saved. This view has been refreshed.'
            : 'Expense saved. It is outside the current period or filter.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Go to today',
              child: TextButton(
                onPressed: _controller.isCurrentPeriod
                    ? null
                    : () => unawaited(_controller.goToToday()),
                child: const Text('Today'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
        tooltip: 'Add expense',
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final status = _controller.status;
    final snapshot = _controller.snapshot;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: <Widget>[
                HistoryRangeControls(
                  rangeType: _controller.rangeType,
                  onRangeChanged: (rangeType) =>
                      unawaited(_controller.changeRange(rangeType)),
                  onPrevious: () => unawaited(_controller.goToPrevious()),
                  onNext: () => unawaited(_controller.goToNext()),
                  canGoPrevious: _controller.canGoPrevious,
                  canGoNext: _controller.canGoNext,
                  periodLabel: _PeriodLabel(
                    label: formatPeriodLabel(
                      rangeKind: _controller.rangeType.name,
                      start: _controller.period.start,
                      end: _controller.period.end,
                    ),
                    currentIndicator: currentPeriodIndicator(
                      _controller.isCurrentPeriod,
                      _controller.rangeType.name,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                HistoryFilterControl(
                  categories: _controller.categories,
                  filter: _controller.filter,
                  onSelected: (filter) =>
                      unawaited(_controller.selectFilter(filter)),
                  onClear: () => unawaited(_controller.clearFilter()),
                ),
              ],
            ),
          ),
        ),
        if (status == HistoryStatus.stale)
          SliverToBoxAdapter(
            child: HistoryStaleBanner(
              message: _controller.failure?.userMessage ??
                  'Refresh failed; these values may be out of date.',
              onRetry: () => unawaited(_controller.load()),
            ),
          ),
        if (status != HistoryStatus.loading &&
            status != HistoryStatus.unavailable &&
            snapshot != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SummaryCard(
                totalMinor: snapshot.totalMinor,
                count: snapshot.count,
                rangeType: snapshot.period.rangeType,
                filtered: snapshot.filter is SelectedCategory,
              ),
            ),
          ),
        ..._buildContentSlivers(),
      ],
    );
  }

  List<Widget> _buildContentSlivers() {
    switch (_controller.status) {
      case HistoryStatus.loading:
        return <Widget>[
          _stateSliver(
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading history…'),
                  ],
                ),
              ),
            ),
          ),
        ];
      case HistoryStatus.unavailable:
        return <Widget>[
          _stateSliver(
            HistoryStates.unavailable(
              failure: _controller.failure,
              onRetry: () => unawaited(_controller.load()),
            ),
          ),
        ];
      case HistoryStatus.emptyEver:
        return <Widget>[
          _stateSliver(HistoryStates.emptyEver(onAdd: _openAdd)),
        ];
      case HistoryStatus.emptyPeriod:
        return <Widget>[
          _stateSliver(
            HistoryStates.emptyPeriod(
              onGoToToday: () => unawaited(_controller.goToToday()),
              onAddForSelectedDay: _controller.rangeType == HistoryRangeType.day
                  ? _openAdd
                  : null,
            ),
          ),
        ];
      case HistoryStatus.noFilterMatches:
        return <Widget>[
          _stateSliver(
            HistoryStates.noFilterMatches(
              onClearFilter: () => unawaited(_controller.clearFilter()),
            ),
          ),
        ];
      case HistoryStatus.available:
      case HistoryStatus.stale:
        final snapshot = _controller.snapshot;
        if (snapshot == null) {
          return <Widget>[
            _stateSliver(
              HistoryStates.unavailable(
                failure: _controller.failure,
                onRetry: () => unawaited(_controller.load()),
              ),
            ),
          ];
        }
        return <Widget>[
          _HistoryList(snapshot: snapshot, onRowTap: _openDetails),
        ];
    }
  }

  Widget _stateSliver(Widget child) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: child,
        ),
      );
}

class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel({
    required this.label,
    required this.currentIndicator,
  });

  final String label;
  final String currentIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (currentIndicator.isNotEmpty)
          Text(
            currentIndicator,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalMinor,
    required this.count,
    required this.rangeType,
    required this.filtered,
  });

  final int totalMinor;
  final int count;
  final HistoryRangeType rangeType;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = filtered
        ? 'Filtered spending in this ${rangeType.unitLabel}'
        : 'Spent in this ${rangeType.unitLabel}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                Text(
                  MoneyText.formatMinor(totalMinor),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _countLabel(count),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 expense' : '$count expenses';
}

sealed class _HistoryEntry {
  const _HistoryEntry();
}

final class _GroupEntry extends _HistoryEntry {
  const _GroupEntry(this.group);

  final DateGroup group;
}

final class _RowEntry extends _HistoryEntry {
  const _RowEntry(this.expense);

  final Expense expense;
}

final class _NoticeEntry extends _HistoryEntry {
  const _NoticeEntry();
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.snapshot,
    required this.onRowTap,
  });

  final HistorySnapshot snapshot;
  final void Function(Expense expense) onRowTap;

  @override
  Widget build(BuildContext context) {
    final entries = <_HistoryEntry>[];
    for (final group in snapshot.groups) {
      entries.add(_GroupEntry(group));
      for (final expense in group.expenses) {
        entries.add(_RowEntry(expense));
      }
    }
    entries.add(const _NoticeEntry());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = entries[index];
            switch (entry) {
              case _GroupEntry(:final group):
                return _DateGroupHeader(group: group);
              case _RowEntry(:final expense):
                return ExpenseListRow(
                  expense: expense,
                  onTap: () => onRowTap(expense),
                );
              case _NoticeEntry():
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: StorageNotice(),
                );
            }
          },
          childCount: entries.length,
        ),
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.group});

  final DateGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                formatDateGroupLabel(group.date),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              MoneyText.formatMinor(group.subtotalMinor),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
