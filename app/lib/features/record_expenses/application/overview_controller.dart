import 'package:flutter/foundation.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/local_date.dart';
import '../data/expense_repository.dart';
import '../domain/overview_snapshot.dart';

enum OverviewStatus {
  loading,
  emptyEver,
  emptyToday,
  available,
  unavailable,
  stale,
}

class OverviewController extends ChangeNotifier {
  OverviewController({
    required this.repository,
    LocalDate Function()? clock,
  }) : _clock = clock ?? LocalDate.today;

  final ExpenseRepository repository;
  final LocalDate Function() _clock;

  OverviewStatus _status = OverviewStatus.loading;
  OverviewSnapshot? _snapshot;
  AppFailure? _failure;
  bool _disposed = false;

  OverviewStatus get status => _status;
  OverviewSnapshot? get snapshot => _snapshot;
  AppFailure? get failure => _failure;
  LocalDate get today => _clock();
  bool get isStale => _status == OverviewStatus.stale;

  Future<void> load() async {
    final hadSnapshot = _snapshot != null;
    if (!hadSnapshot) {
      _status = OverviewStatus.loading;
      _notify();
    }

    final result = await repository.loadOverview(_clock());
    switch (result) {
      case Success<OverviewSnapshot>(:final value):
        _snapshot = value;
        _failure = null;
        if (!value.hasAnyExpenses) {
          _status = OverviewStatus.emptyEver;
        } else if (value.todayRows.isEmpty) {
          _status = OverviewStatus.emptyToday;
        } else {
          _status = OverviewStatus.available;
        }
      case Failure<OverviewSnapshot>(:final failure):
        _failure = failure;
        _status = hadSnapshot ? OverviewStatus.stale : OverviewStatus.unavailable;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
