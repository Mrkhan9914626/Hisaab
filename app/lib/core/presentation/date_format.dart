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
