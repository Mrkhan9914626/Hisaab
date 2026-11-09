import '../../../core/domain/local_date.dart';
import '../../../core/domain/money.dart';
import 'category.dart';
import 'entry_draft.dart';
import 'submission.dart';

class EntryValidator {
  const EntryValidator();

  static ValidationResult validate(
    EntryDraft draft,
    LocalDate today,
    List<Category> activeCategories,
  ) {
    final errors = <String, String>{};
    Money? amount;

    final parsed = Money.parse(draft.amountText);
    if (parsed.error != null) {
      errors['amount'] = switch (parsed.error!) {
        MoneyParseError.blank => 'Enter an amount.',
        MoneyParseError.invalidFormat => 'Enter an amount like 650.25.',
        MoneyParseError.belowMinimum => 'Enter at least PKR 0.01.',
        MoneyParseError.aboveMaximum => 'Enter at most PKR 999,999,999.00.',
      };
    } else {
      amount = parsed.value;
    }

    final selectedCategoryId = draft.categoryId;
    Category? selectedCategory;
    if (selectedCategoryId != null) {
      for (final category in activeCategories) {
        if (category.id == selectedCategoryId) {
          selectedCategory = category;
          break;
        }
      }
    }
    if (selectedCategory == null) {
      errors['category'] = 'Choose a category.';
    }

    if (draft.date.isAfter(today)) {
      errors['date'] = 'Choose today or an earlier date.';
    }

    final note = Note.canonical(draft.noteText);
    if (note != null && !note.isValid) {
      errors['note'] = 'Use 200 characters or fewer.';
    }

    if (errors.isNotEmpty) {
      return InvalidEntry(Map.unmodifiable(errors));
    }

    return ValidEntry(
      ValidatedEntry(
        amount: amount!,
        categoryId: selectedCategoryId!,
        date: draft.date,
        note: note,
      ),
    );
  }
}
