import '../domain/local_date.dart';

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatCivilDate(LocalDate date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// Readable label for one date group inside a history period.
String formatDateGroupLabel(LocalDate date) => formatCivilDate(date);

/// Readable label for an inclusive civil-date range.
String formatRangeLabel(LocalDate start, LocalDate end) {
  if (start == end) {
    return formatCivilDate(start);
  }
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${end.day} ${_monthNames[start.month - 1]} ${start.year}';
  }
  if (start.year == end.year) {
    return '${start.day} ${_monthNames[start.month - 1]} – '
        '${end.day} ${_monthNames[end.month - 1]} ${start.year}';
  }
  return '${formatCivilDate(start)} – ${formatCivilDate(end)}';
}

/// Label naming the selected period for [rangeKind] (`day`, `week`, `month`).
String formatPeriodLabel({
  required String rangeKind,
  required LocalDate start,
  required LocalDate end,
}) {
  switch (rangeKind) {
    case 'day':
      return formatCivilDate(start);
    case 'week':
      return 'Week of ${formatRangeLabel(start, end)}';
    case 'month':
      return '${_monthNames[start.month - 1]} ${start.year}';
    default:
      return formatRangeLabel(start, end);
  }
}

/// Visible current-period marker, or an empty string when not current.
String currentPeriodIndicator(bool isCurrent, String rangeKind) {
  if (!isCurrent) {
    return '';
  }
  switch (rangeKind) {
    case 'day':
      return 'Current day';
    case 'week':
      return 'Current week';
    case 'month':
      return 'Current month';
    default:
      return 'Current period';
  }
}
