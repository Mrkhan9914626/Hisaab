import '../../../core/domain/calendar_range.dart';
import '../../../core/domain/local_date.dart';

/// The active history range. Exactly one range type is selected at a time.
enum HistoryRangeType {
  day,
  week,
  month;

  String get unitLabel => switch (this) {
        HistoryRangeType.day => 'day',
        HistoryRangeType.week => 'week',
        HistoryRangeType.month => 'month',
      };

  String get titleLabel => switch (this) {
        HistoryRangeType.day => 'Day',
        HistoryRangeType.week => 'Week',
        HistoryRangeType.month => 'Month',
      };
}

/// An inclusive local civil-date period for one history selection.
class HistoryPeriod {
  const HistoryPeriod({
    required this.rangeType,
    required this.start,
    required this.end,
  });

  factory HistoryPeriod.forAnchor(
    HistoryRangeType rangeType,
    LocalDate anchor,
  ) {
    switch (rangeType) {
      case HistoryRangeType.day:
        return HistoryPeriod(rangeType: rangeType, start: anchor, end: anchor);
      case HistoryRangeType.week:
        var start = CalendarRange.weekStart(anchor) ?? CalendarRange.domainStart;
        if (start.isBefore(CalendarRange.domainStart)) {
          start = CalendarRange.domainStart;
        }
        var end = CalendarRange.addDays(start, 6) ?? CalendarRange.domainEnd;
        if (end.isAfter(CalendarRange.domainEnd)) {
          end = CalendarRange.domainEnd;
        }
        return HistoryPeriod(rangeType: rangeType, start: start, end: end);
      case HistoryRangeType.month:
        return HistoryPeriod(
          rangeType: rangeType,
          start: CalendarRange.monthStart(anchor),
          end: CalendarRange.monthEnd(anchor),
        );
    }
  }

  final HistoryRangeType rangeType;
  final LocalDate start;
  final LocalDate end;

  bool contains(LocalDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  bool isSamePeriod(HistoryPeriod other) =>
      rangeType == other.rangeType &&
      start == other.start &&
      end == other.end;

  HistoryPeriod? previous() {
    switch (rangeType) {
      case HistoryRangeType.day:
        final previousStart = CalendarRange.addDays(start, -1);
        return previousStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, previousStart);
      case HistoryRangeType.week:
        final previousStart = CalendarRange.addDays(start, -7);
        return previousStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, previousStart);
      case HistoryRangeType.month:
        final previousStart = CalendarRange.addMonthsClamped(start, -1);
        return previousStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, previousStart);
    }
  }

  HistoryPeriod? next() {
    switch (rangeType) {
      case HistoryRangeType.day:
        final nextStart = CalendarRange.addDays(start, 1);
        return nextStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, nextStart);
      case HistoryRangeType.week:
        final nextStart = CalendarRange.addDays(start, 7);
        return nextStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, nextStart);
      case HistoryRangeType.month:
        final nextStart = CalendarRange.addMonthsClamped(start, 1);
        return nextStart == null
            ? null
            : HistoryPeriod.forAnchor(rangeType, nextStart);
    }
  }

  static HistoryPeriod earliest(HistoryRangeType rangeType) =>
      HistoryPeriod.forAnchor(rangeType, CalendarRange.domainStart);

  static HistoryPeriod laterOf(HistoryPeriod first, HistoryPeriod second) =>
      first.start.isBefore(second.start) ? second : first;

  @override
  bool operator ==(Object other) =>
      other is HistoryPeriod &&
      other.rangeType == rangeType &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(rangeType, start, end);

  @override
  String toString() => 'HistoryPeriod(${rangeType.name}, $start..$end)';
}

/// Navigation bounds for the active range, derived from saved data and the
/// injected local clock.
class NavigationLimits {
  const NavigationLimits({
    required this.earliestPeriod,
    required this.latestReachablePeriod,
  });

  factory NavigationLimits.forSnapshot({
    required HistoryRangeType rangeType,
    required LocalDate today,
    required LocalDate? latestExpenseDate,
  }) {
    final currentPeriod = HistoryPeriod.forAnchor(rangeType, today);
    final latestSavedPeriod = latestExpenseDate == null
        ? null
        : HistoryPeriod.forAnchor(rangeType, latestExpenseDate);
    final latestReachablePeriod = latestSavedPeriod == null ||
            !latestSavedPeriod.start.isAfter(currentPeriod.start)
        ? currentPeriod
        : latestSavedPeriod;
    return NavigationLimits(
      earliestPeriod: HistoryPeriod.earliest(rangeType),
      latestReachablePeriod: latestReachablePeriod,
    );
  }

  final HistoryPeriod earliestPeriod;
  final HistoryPeriod latestReachablePeriod;

  bool canGoPrevious(HistoryPeriod selected) =>
      selected.start.isAfter(earliestPeriod.start);

  bool canGoNext(HistoryPeriod selected) =>
      selected.start.isBefore(latestReachablePeriod.start);
}

/// Presentation text plus the current-period marker for a selection.
///
/// The label never participates in period identity or money arithmetic.
class HistoryPeriodLabel {
  const HistoryPeriodLabel({
    required this.text,
    required this.isCurrent,
  });

  final String text;
  final bool isCurrent;
}
