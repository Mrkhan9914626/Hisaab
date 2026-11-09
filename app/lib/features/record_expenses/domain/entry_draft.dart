import '../../../core/domain/local_date.dart';
import '../../../core/domain/money.dart';
import 'submission.dart';

class EntryDraft {
  const EntryDraft({
    required this.amountText,
    required this.categoryId,
    required this.date,
    required this.noteText,
  });

  final String amountText;
  final String? categoryId;
  final LocalDate date;
  final String noteText;

  static EntryDraft fresh({required LocalDate today}) => EntryDraft(
        amountText: '',
        categoryId: null,
        date: today,
        noteText: '',
      );

  EntryDraft copyWith({
    String? amountText,
    String? categoryId,
    bool clearCategory = false,
    LocalDate? date,
    String? noteText,
  }) =>
      EntryDraft(
        amountText: amountText ?? this.amountText,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        date: date ?? this.date,
        noteText: noteText ?? this.noteText,
      );

  bool sameValuesAs(EntryDraft other) =>
      amountText == other.amountText &&
      categoryId == other.categoryId &&
      date == other.date &&
      noteText == other.noteText;
}

class ValidatedEntry {
  const ValidatedEntry({
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
  });

  final Money amount;
  final String categoryId;
  final LocalDate date;
  final Note? note;
}

sealed class ValidationResult {
  const ValidationResult();
}

final class ValidEntry extends ValidationResult {
  const ValidEntry(this.value);

  final ValidatedEntry value;
}

final class InvalidEntry extends ValidationResult {
  const InvalidEntry(this.fieldErrors);

  final Map<String, String> fieldErrors;
}
