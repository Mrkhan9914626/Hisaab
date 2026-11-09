import 'package:characters/characters.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/domain/money.dart';

class ExpenseId {
  const ExpenseId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is ExpenseId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Optional note text.
///
/// Blank/whitespace-only input canonicalizes to `null`. Nonblank text is
/// preserved exactly, including spaces and line breaks.
class Note {
  const Note._(this.text);

  static const int maxGraphemeClusters = 200;

  final String text;

  static Note? canonical(String raw) =>
      raw.trim().isEmpty ? null : Note._(raw);

  static Note persisted(String text) => Note._(text);

  int get graphemeLength => text.characters.length;

  bool get isValid => graphemeLength <= maxGraphemeClusters;

  bool get isBlank => text.trim().isEmpty;

  @override
  bool operator ==(Object other) => other is Note && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}

/// Immutable payload frozen on first valid Save.
class ImmutableSubmission {
  const ImmutableSubmission({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
  });

  final ExpenseId id;
  final Money amount;
  final String categoryId;
  final LocalDate date;
  final Note? note;

  bool samePayload(ImmutableSubmission other) =>
      id == other.id &&
      amount == other.amount &&
      categoryId == other.categoryId &&
      date == other.date &&
      note == other.note;
}
