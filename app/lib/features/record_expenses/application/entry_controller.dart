import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/local_date.dart';
import '../application/save_coordinator.dart';
import '../data/expense_repository.dart';
import '../domain/category.dart';
import '../domain/entry_draft.dart';
import '../domain/entry_validator.dart';
import '../domain/submission.dart';

sealed class LeaveDecision {
  const LeaveDecision();
}

final class LeaveImmediately extends LeaveDecision {
  const LeaveImmediately();
}

final class ConfirmDiscardLeave extends LeaveDecision {
  const ConfirmDiscardLeave();
}

final class SavePendingLeave extends LeaveDecision {
  const SavePendingLeave();
}

class EntryController extends ChangeNotifier {
  EntryController({
    required this.repository,
    required this.coordinator,
    Uuid? uuid,
    LocalDate Function()? clock,
  })  : _uuid = uuid ?? Uuid(),
        _clock = clock ?? LocalDate.today {
    _draft = EntryDraft.fresh(today: _clock());
    _initial = _draft;
  }

  final ExpenseRepository repository;
  final SaveCoordinator coordinator;

  final Uuid _uuid;
  final LocalDate Function() _clock;

  late EntryDraft _draft;
  late EntryDraft _initial;

  List<Category> _categories = const <Category>[];
  Map<String, String> _errors = const <String, String>{};
  bool _loadingCategories = true;
  AppFailure? _categoryFailure;

  SaveOperation? _operation;
  ImmutableSubmission? _lastSubmission;
  SaveProgress? _progress;
  SaveOutcome? _outcome;
  StreamSubscription<SaveProgress>? _progressSubscription;
  bool _disposed = false;

  EntryDraft get draft => _draft;
  List<Category> get categories => _categories;
  Map<String, String> get errors => _errors;
  bool get loadingCategories => _loadingCategories;
  AppFailure? get categoryFailure => _categoryFailure;
  SaveProgress? get progress => _progress;
  SaveOutcome? get outcome => _outcome;
  bool get isDirty => !_draft.sameValuesAs(_initial);
  bool get hasPendingSave => _operation != null && _outcome == null;

  Future<void> loadCategories() async {
    _loadingCategories = true;
    _notify();
    final result = await repository.listActiveCategories();
    switch (result) {
      case Success<List<Category>>(:final value):
        _categories = value;
        _categoryFailure = null;
      case Failure<List<Category>>(:final failure):
        _categoryFailure = failure;
    }
    _loadingCategories = false;
    _notify();
  }

  void updateAmount(String text) {
    _draft = _draft.copyWith(amountText: text);
    _clearError('amount');
    _notify();
  }

  void selectCategory(String categoryId) {
    _draft = _draft.copyWith(categoryId: categoryId);
    _clearError('category');
    _notify();
  }

  void selectDate(LocalDate date) {
    _draft = _draft.copyWith(date: date);
    _clearError('date');
    _notify();
  }

  void updateNote(String text) {
    _draft = _draft.copyWith(noteText: text);
    _clearError('note');
    _notify();
  }

  Future<SaveOutcome?> save() async {
    final pending = _operation;
    if (pending != null && _outcome == null) {
      return pending.outcome;
    }

    final validation = EntryValidator.validate(_draft, _clock(), _categories);
    if (validation is InvalidEntry) {
      _errors = validation.fieldErrors;
      _notify();
      return null;
    }

    final entry = (validation as ValidEntry).value;
    final submission = ImmutableSubmission(
      id: ExpenseId(_uuid.v4()),
      amount: entry.amount,
      categoryId: entry.categoryId,
      date: entry.date,
      note: entry.note,
    );
    _lastSubmission = submission;
    _errors = const <String, String>{};
    _outcome = null;
    return _startOperation(submission);
  }

  Future<SaveOutcome?> retry() async {
    final submission = _lastSubmission;
    if (submission == null) {
      return null;
    }
    _outcome = null;
    return _startOperation(submission);
  }

  Future<SaveOutcome> reconcile() async {
    final submission = _lastSubmission;
    if (submission == null) {
      return const OutcomeUnavailable(
        AppFailure(
          AppFailureCode.outcomeUnavailable,
          retryKind: RetryKind.reconciliation,
        ),
      );
    }
    final outcome = await coordinator.reconcile(submission.id);
    _outcome = outcome;
    _notify();
    return outcome;
  }

  Future<SaveOutcome?> cancelPendingSave() async {
    final operation = _operation;
    if (operation == null) {
      return null;
    }
    final outcome = await coordinator.requestCancellation(operation.submission.id);
    _outcome = outcome;
    _progress = null;
    _notify();
    return outcome;
  }

  LeaveDecision requestLeave() {
    if (hasPendingSave || _outcome is OutcomeUnavailable) {
      return const SavePendingLeave();
    }
    if (_draft.sameValuesAs(_initial)) {
      return const LeaveImmediately();
    }
    return const ConfirmDiscardLeave();
  }

  void markInitialValues() {
    _initial = _draft;
    _notify();
  }

  Future<SaveOutcome?> _startOperation(ImmutableSubmission submission) async {
    final operation = coordinator.begin(submission);
    _operation = operation;
    _progress = SaveProgress.queued;

    final previous = _progressSubscription;
    _progressSubscription = operation.progress.listen((progress) {
      _progress = progress;
      _notify();
    });
    unawaited(previous?.cancel());
    _notify();

    final outcome = await operation.outcome;
    await _progressSubscription?.cancel();
    _progressSubscription = null;
    _progress = null;
    _outcome = outcome;
    _notify();
    return outcome;
  }

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      final updated = Map<String, String>.from(_errors)..remove(field);
      _errors = Map.unmodifiable(updated);
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_progressSubscription?.cancel());
    super.dispose();
  }
}
