import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/presentation/date_format.dart';
import '../application/entry_controller.dart';
import '../application/save_coordinator.dart';
import '../data/expense_repository.dart';
import '../domain/submission.dart';
import 'discard_dialog.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.repository,
    required this.coordinator,
  });

  final ExpenseRepository repository;
  final SaveCoordinator coordinator;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final EntryController _controller;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _categoryFocus = FocusNode();
  final FocusNode _dateFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  bool _busy = false;
  bool _needsReconcile = false;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _controller = EntryController(
      repository: widget.repository,
      coordinator: widget.coordinator,
    );
    _controller.addListener(_onChanged);
    unawaited(_controller.loadCategories());
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _categoryFocus.dispose();
    _dateFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = LocalDate.today();
    final draftDate = _controller.draft.date;
    final initial = draftDate.isAfter(today) ? today : draftDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toDateTime(),
      firstDate: DateTime(1),
      lastDate: today.toDateTime(),
    );
    if (picked != null) {
      _controller.selectDate(LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (_busy || _controller.hasPendingSave) {
      return;
    }
    setState(() {
      _busy = true;
      _banner = null;
      _needsReconcile = false;
    });
    final outcome = await _controller.save();
    if (!mounted) {
      return;
    }
    if (outcome == null) {
      setState(() => _busy = false);
      _focusFirstInvalid();
      return;
    }
    setState(() => _busy = false);
    _handleOutcome(outcome);
  }

  Future<void> _retry() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _banner = null;
    });
    final outcome = await _controller.retry();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (outcome != null) {
      _handleOutcome(outcome);
    }
  }

  Future<void> _checkAgain() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final outcome = await _controller.reconcile();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    _handleOutcome(outcome);
  }

  void _handleOutcome(SaveOutcome outcome) {
    switch (outcome) {
      case Saved(:final expense):
        final message =
            'Saved ${expense.amount.formatPkr()} on ${formatCivilDate(expense.date)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop(true);
      case Cancelled():
        Navigator.of(context).pop(false);
      case KnownUnsaved(:final failure):
        setState(() {
          _banner = failure.userMessage;
          _needsReconcile = false;
        });
      case OutcomeUnavailable(:final failure):
        setState(() {
          _banner = failure.userMessage;
          _needsReconcile = true;
        });
    }
  }

  void _focusFirstInvalid() {
    const order = <String>['amount', 'category', 'date', 'note'];
    for (final field in order) {
      if (_controller.errors.containsKey(field)) {
        _focusField(field);
        break;
      }
    }
    SemanticsService.announce(
      'Check the highlighted fields.',
      Directionality.of(context),
    );
  }

  void _focusField(String field) {
    switch (field) {
      case 'amount':
        _amountFocus.requestFocus();
      case 'category':
        _categoryFocus.requestFocus();
      case 'date':
        _dateFocus.requestFocus();
      case 'note':
        _noteFocus.requestFocus();
    }
  }

  Future<void> _handleBack() async {
    final decision = _controller.requestLeave();
    switch (decision) {
      case LeaveImmediately():
        Navigator.of(context).pop(_controller.outcome is Saved);
      case ConfirmDiscardLeave():
        final choice = await showDiscardExpenseDialog(context);
        if (choice == DiscardChoice.discard && mounted) {
          Navigator.of(context).pop(false);
        }
      case SavePendingLeave():
        final shouldCancel = await showCancelPendingSaveDialog(context);
        if (!shouldCancel || !mounted) {
          return;
        }
        setState(() => _busy = true);
        final outcome = await _controller.cancelPendingSave();
        if (!mounted) {
          return;
        }
        setState(() => _busy = false);
        if (outcome != null) {
          _handleOutcome(outcome);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_handleBack());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: SafeArea(
          top: false,
          child: _controller.loadingCategories
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final errors = _controller.errors;
    final draft = _controller.draft;
    final locked =
        _busy || _controller.hasPendingSave || _needsReconcile;
    final noteLength = Note.canonical(draft.noteText)?.graphemeLength ?? 0;
    final progressLabel = _progressLabel(_controller.progress);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_banner != null) ...[
          _ActionBanner(
            message: _banner!,
            actionLabel: _needsReconcile ? 'Check result again' : 'Retry',
            onAction: _needsReconcile ? _checkAgain : _retry,
          ),
          const SizedBox(height: 12),
        ],
        if (_controller.categoryFailure != null &&
            _controller.categories.isEmpty) ...[
          _ActionBanner(
            message: _controller.categoryFailure!.userMessage,
            actionLabel: 'Retry',
            onAction: _controller.loadCategories,
          ),
          const SizedBox(height: 12),
        ],
        if (errors.isNotEmpty) ...[
          _ErrorSummary(errors: errors, onFieldTap: _focusField),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _amountController,
          focusNode: _amountFocus,
          enabled: !locked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Amount (PKR)',
            hintText: '0.00',
            errorText: errors['amount'],
          ),
          onChanged: _controller.updateAmount,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          focusNode: _categoryFocus,
          initialValue: draft.categoryId,
          decoration: InputDecoration(
            labelText: 'Category',
            errorText: errors['category'],
          ),
          items: [
            for (final category in _controller.categories)
              DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              ),
          ],
          onChanged: locked
              ? null
              : (value) {
                  if (value != null) {
                    _controller.selectCategory(value);
                  }
                },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          focusNode: _dateFocus,
          onPressed: locked ? null : _pickDate,
          icon: const Icon(Icons.event),
          label: Text('Date: ${formatCivilDate(draft.date)}'),
        ),
        if (errors['date'] != null) ...[
          const SizedBox(height: 6),
          Text(
            errors['date']!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          focusNode: _noteFocus,
          enabled: !locked,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            helperText: '$noteLength/${Note.maxGraphemeClusters}',
            errorText: errors['note'],
          ),
          onChanged: _controller.updateNote,
        ),
        const SizedBox(height: 16),
        if (progressLabel != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(progressLabel, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: locked ? null : _save,
          icon: const Icon(Icons.check),
          label: const Text('Save expense'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => unawaited(_handleBack()),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static String? _progressLabel(SaveProgress? progress) {
    switch (progress) {
      case SaveProgress.queued:
        return 'Queued to save…';
      case SaveProgress.writing:
        return 'Saving…';
      case SaveProgress.cancelling:
        return 'Cancelling…';
      case SaveProgress.checkingOutcome:
        return 'Checking the result…';
      case null:
        return null;
    }
  }
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({
    required this.errors,
    required this.onFieldTap,
  });

  final Map<String, String> errors;
  final ValueChanged<String> onFieldTap;

  static const List<String> _order = <String>[
    'amount',
    'category',
    'date',
    'note',
  ];

  static const Map<String, String> _labels = <String, String>{
    'amount': 'Amount',
    'category': 'Category',
    'date': 'Date',
    'note': 'Note',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Form errors',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check these fields',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final field in _order)
                if (errors[field] != null)
                  InkWell(
                    onTap: () => onFieldTap(field),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${_labels[field]}: ${errors[field]}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final FutureOr<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => onAction(),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
