import 'dart:async';

import '../../../core/domain/app_failure.dart';
import '../data/expense_repository.dart';
import '../data/write_cancellation.dart';
import '../domain/expense.dart';
import '../domain/submission.dart';

enum SaveProgress {
  queued,
  writing,
  cancelling,
  checkingOutcome,
}

sealed class SaveOutcome {
  const SaveOutcome();
}

final class Saved extends SaveOutcome {
  const Saved(this.expense);

  final Expense expense;
}

final class Cancelled extends SaveOutcome {
  const Cancelled();
}

final class KnownUnsaved extends SaveOutcome {
  const KnownUnsaved(this.failure);

  final AppFailure failure;
}

final class OutcomeUnavailable extends SaveOutcome {
  const OutcomeUnavailable(this.failure);

  final AppFailure failure;
}

class SaveOperation {
  SaveOperation(this.submission);

  final ImmutableSubmission submission;
  final WriteCancellation cancellation = WriteCancellation();

  final StreamController<SaveProgress> _progressController =
      StreamController<SaveProgress>.broadcast();
  final Completer<SaveOutcome> _outcomeCompleter = Completer<SaveOutcome>();

  bool _cancelRequested = false;

  bool get cancelRequested => _cancelRequested;

  Stream<SaveProgress> get progress => _progressController.stream;

  Future<SaveOutcome> get outcome => _outcomeCompleter.future;

  void emitProgress(SaveProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  void requestCancel() {
    _cancelRequested = true;
    cancellation.isCancelled = true;
    emitProgress(SaveProgress.cancelling);
  }

  void complete(SaveOutcome outcome) {
    if (!_outcomeCompleter.isCompleted) {
      _outcomeCompleter.complete(outcome);
    }
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }
}

typedef _SettledSave = ({
  ImmutableSubmission submission,
  SaveOutcome outcome,
  bool cancelRequested,
});

class SaveCoordinator {
  SaveCoordinator(this._repository);

  final ExpenseRepository _repository;
  final Map<String, SaveOperation> _operations = <String, SaveOperation>{};
  final Map<String, _SettledSave> _settled = <String, _SettledSave>{};

  SaveOperation begin(ImmutableSubmission submission) {
    final key = submission.id.value;
    final existing = _operations[key];
    if (existing != null) {
      if (existing.submission.samePayload(submission)) {
        return existing;
      }
      final conflicting = SaveOperation(submission);
      conflicting.complete(
        const KnownUnsaved(AppFailure(AppFailureCode.integrityFailure)),
      );
      return conflicting;
    }

    final settled = _settled[key];
    if (settled != null) {
      if (!settled.submission.samePayload(submission)) {
        final conflicting = SaveOperation(submission);
        conflicting.complete(
          const KnownUnsaved(AppFailure(AppFailureCode.integrityFailure)),
        );
        return conflicting;
      }
      if (settled.outcome is KnownUnsaved || settled.outcome is Cancelled) {
        _settled.remove(key);
      } else {
        final replay = SaveOperation(submission);
        replay.complete(settled.outcome);
        return replay;
      }
    }

    final operation = SaveOperation(submission);
    _operations[key] = operation;
    operation.emitProgress(SaveProgress.queued);
    scheduleMicrotask(() => unawaited(_run(operation)));
    return operation;
  }

  Future<void> _run(SaveOperation operation) async {
    operation.emitProgress(SaveProgress.writing);
    try {
      final result = await _repository.createExpense(
        operation.submission,
        cancellation: operation.cancellation,
      );
      switch (result) {
        case Success<Expense>(:final value):
          _settle(operation, Saved(value));
        case Failure<Expense>(:final failure):
          _settle(operation, KnownUnsaved(failure));
      }
    } on CancellationRollback {
      _settle(operation, const Cancelled());
    } on UncertainWriteException {
      try {
        await _repository.quarantineAfterUncertainWrite();
      } catch (_) {
        // Reconciliation still starts from a fresh connection and fence.
      }
      _settle(
        operation,
        const OutcomeUnavailable(
          AppFailure(
            AppFailureCode.outcomeUnavailable,
            retryKind: RetryKind.reconciliation,
          ),
        ),
      );
    } catch (_) {
      _settle(
        operation,
        const OutcomeUnavailable(
          AppFailure(
            AppFailureCode.outcomeUnavailable,
            retryKind: RetryKind.reconciliation,
          ),
        ),
      );
    }
  }

  void _settle(SaveOperation operation, SaveOutcome outcome) {
    _operations.remove(operation.submission.id.value);
    _settleRecord(
      operation.submission,
      outcome,
      cancelRequested: operation.cancelRequested,
    );
    operation.complete(outcome);
  }

  void _settleRecord(
    ImmutableSubmission submission,
    SaveOutcome outcome, {
    required bool cancelRequested,
  }) {
    _settled[submission.id.value] = (
      submission: submission,
      outcome: outcome,
      cancelRequested: cancelRequested,
    );
  }

  Future<SaveOutcome> requestCancellation(ExpenseId id) async {
    final key = id.value;
    final settled = _settled[key];
    if (settled != null) {
      return settled.outcome;
    }
    final operation = _operations[key];
    if (operation == null) {
      return const KnownUnsaved(AppFailure(AppFailureCode.integrityFailure));
    }
    operation.requestCancel();
    return operation.outcome;
  }

  Future<SaveOutcome> reconcile(ExpenseId id) async {
    final key = id.value;
    final initial = _settled[key];
    if (initial != null && initial.outcome is! OutcomeUnavailable) {
      return initial.outcome;
    }

    final operation = _operations[key];
    if (operation != null) {
      operation.emitProgress(SaveProgress.checkingOutcome);
      final outcome = await operation.outcome;
      if (outcome is! OutcomeUnavailable) {
        return outcome;
      }
    }

    final settled = _settled[key];
    if (settled == null) {
      return _recoverUnknown(id);
    }

    try {
      final result = await _repository.recoverAndFind(settled.submission.id);
      switch (result) {
        case Failure<Expense?>():
          return const OutcomeUnavailable(
            AppFailure(
              AppFailureCode.outcomeUnavailable,
              retryKind: RetryKind.reconciliation,
            ),
          );
        case Success<Expense?>(:final value):
          if (value == null) {
            final outcome = settled.cancelRequested
                ? const Cancelled()
                : const KnownUnsaved(
                    AppFailure(AppFailureCode.storageUnavailable),
                  );
            _settleRecord(
              settled.submission,
              outcome,
              cancelRequested: settled.cancelRequested,
            );
            return outcome;
          }

          if (!value.matchesSubmission(settled.submission)) {
            final outcome = const KnownUnsaved(
              AppFailure(AppFailureCode.integrityFailure),
            );
            _settleRecord(
              settled.submission,
              outcome,
              cancelRequested: settled.cancelRequested,
            );
            return outcome;
          }

          final outcome = Saved(value);
          _settleRecord(
            settled.submission,
            outcome,
            cancelRequested: settled.cancelRequested,
          );
          return outcome;
      }
    } catch (_) {
      return const OutcomeUnavailable(
        AppFailure(
          AppFailureCode.outcomeUnavailable,
          retryKind: RetryKind.reconciliation,
        ),
      );
    }
  }

  Future<SaveOutcome> _recoverUnknown(ExpenseId id) async {
    try {
      final result = await _repository.recoverAndFind(id);
      switch (result) {
        case Failure<Expense?>():
          return const OutcomeUnavailable(
            AppFailure(
              AppFailureCode.outcomeUnavailable,
              retryKind: RetryKind.reconciliation,
            ),
          );
        case Success<Expense?>(:final value):
          if (value == null) {
            return const KnownUnsaved(
              AppFailure(AppFailureCode.integrityFailure),
            );
          }
          final outcome = Saved(value);
          _settleRecord(
            ImmutableSubmission(
              id: value.id,
              amount: value.amount,
              categoryId: value.category.id,
              date: value.date,
              note: value.note,
            ),
            outcome,
            cancelRequested: false,
          );
          return outcome;
      }
    } catch (_) {
      return const OutcomeUnavailable(
        AppFailure(
          AppFailureCode.outcomeUnavailable,
          retryKind: RetryKind.reconciliation,
        ),
      );
    }
  }
}
