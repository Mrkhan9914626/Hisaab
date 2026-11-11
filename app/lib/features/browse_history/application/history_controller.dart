import 'package:flutter/foundation.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/local_date.dart';
import '../../record_expenses/data/expense_repository.dart';
import '../../record_expenses/domain/category.dart';
import '../domain/category_filter.dart';
import '../domain/history_range.dart';
import '../domain/history_snapshot.dart';

/// Owns history selection, filter, navigation and load state.
///
/// A fresh controller starts on the current local day with the Day range and
/// `AllCategories`. The controller never mutates stored expenses or categories.
class HistoryController extends ChangeNotifier {
  HistoryController({
    required this.repository,
    LocalDate Function()? clock,
  }) : _clock = clock ?? LocalDate.today {
    _anchor = _clock();
  }

  final ExpenseRepository repository;
  final LocalDate Function() _clock;

  HistoryRangeType _rangeType = HistoryRangeType.day;
  late LocalDate _anchor;
  CategoryFilter _filter = const AllCategories();
  List<Category> _categories = const <Category>[];
  HistorySnapshot? _snapshot;
  AppFailure? _failure;
  HistoryStatus _status = HistoryStatus.loading;
  bool _loading = false;
  bool _initialized = false;
  bool _disposed = false;
  int _loadGeneration = 0;

  HistoryRangeType get rangeType => _rangeType;
  LocalDate get anchorDate => _anchor;
  HistoryPeriod get period => HistoryPeriod.forAnchor(_rangeType, _anchor);
  CategoryFilter get filter => _filter;
  List<Category> get categories => _categories;
  HistorySnapshot? get snapshot => _snapshot;
  AppFailure? get failure => _failure;
  HistoryStatus get status => _status;
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get isStale => _status == HistoryStatus.stale;

  bool get isCurrentPeriod =>
      period.isSamePeriod(HistoryPeriod.forAnchor(_rangeType, _clock()));

  NavigationLimits get navigationLimits => NavigationLimits.forSnapshot(
        rangeType: _rangeType,
        today: _clock(),
        latestExpenseDate: _snapshot?.latestExpenseDate,
      );

  bool get canGoPrevious => navigationLimits.canGoPrevious(period);

  bool get canGoNext => navigationLimits.canGoNext(period);

  Category? get activeFilterCategory {
    final current = _filter;
    if (current is! SelectedCategory) {
      return null;
    }
    for (final category in _categories) {
      if (category.id == current.categoryId) {
        return category;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    _rangeType = HistoryRangeType.day;
    _anchor = _clock();
    _filter = const AllCategories();
    _initialized = true;
    await load();
  }

  Future<void> changeRange(HistoryRangeType rangeType) async {
    if (rangeType == _rangeType) {
      return;
    }
    _rangeType = rangeType;
    _anchor = _clock();
    await load();
  }

  Future<void> goToPrevious() async {
    if (!canGoPrevious) {
      return;
    }
    final previous = period.previous();
    if (previous == null) {
      return;
    }
    _anchor = previous.start;
    await load();
  }

  Future<void> goToNext() async {
    if (!canGoNext) {
      return;
    }
    final next = period.next();
    if (next == null) {
      return;
    }
    _anchor = next.start;
    await load();
  }

  Future<void> goToToday() async {
    _anchor = _clock();
    await load();
  }

  Future<void> selectFilter(CategoryFilter filter) async {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    await load();
  }

  Future<void> clearFilter() async {
    if (_filter is AllCategories) {
      return;
    }
    _filter = const AllCategories();
    await load();
  }

  Future<void> refresh() => load();

  Future<void> load() async {
    if (!_initialized) {
      return;
    }

    final hadSnapshot = _snapshot != null;
    final generation = ++_loadGeneration;
    _loading = true;
    _status = HistoryStatus.loading;
    _notify();

    if (_categories.isEmpty) {
      final categoriesResult = await repository.listCategoriesForFilter();
      if (generation != _loadGeneration) {
        return;
      }
      switch (categoriesResult) {
        case Success<List<Category>>(:final value):
          _categories = value;
        case Failure<List<Category>>(:final failure):
          _failure = failure;
          _loading = false;
          _status =
              hadSnapshot ? HistoryStatus.stale : HistoryStatus.unavailable;
          _notify();
          return;
      }
    }

    final currentFilter = _filter;
    if (currentFilter is SelectedCategory) {
      final resolved = currentFilter.resolveIn(_categories);
      if (resolved == null) {
        _loading = false;
        _failure = const AppFailure(AppFailureCode.integrityFailure);
        _status = hadSnapshot
            ? HistoryStatus.stale
            : HistoryStatus.unavailable;
        _notify();
        return;
      }
    }

    final result = await repository.loadHistory(
      HistoryQuery(period: period, filter: currentFilter),
    );
    if (generation != _loadGeneration) {
      return;
    }
    switch (result) {
      case Success<HistorySnapshot>(:final value):
        _snapshot = value;
        _failure = null;
        _status = value.status;
      case Failure<HistorySnapshot>(:final failure):
        _failure = failure;
        _status = hadSnapshot ? HistoryStatus.stale : HistoryStatus.unavailable;
    }
    _loading = false;
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
