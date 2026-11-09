import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/features/record_expenses/domain/category.dart';
import 'package:expense_tracker/features/record_expenses/domain/entry_draft.dart';
import 'package:expense_tracker/features/record_expenses/domain/entry_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Category> activeCategories = [
  Category(
    id: 'builtin.food-drinks',
    name: 'Food & drinks',
    iconKey: 'food_drinks',
    isActive: true,
    isProtected: false,
  ),
  Category(
    id: 'builtin.other',
    name: 'Other',
    iconKey: 'other',
    isActive: true,
    isProtected: true,
  ),
];

EntryDraft draft({
  String amount = '10.00',
  String? categoryId = 'builtin.food-drinks',
  LocalDate? date,
  String note = '',
}) =>
    EntryDraft(
      amountText: amount,
      categoryId: categoryId,
      date: date ?? LocalDate(2026, 11, 8),
      noteText: note,
    );

void main() {
  final today = LocalDate(2026, 11, 8);

  test('accepts a complete valid draft', () {
    final result = EntryValidator.validate(draft(), today, activeCategories);
    expect(result, isA<ValidEntry>());
    final value = (result as ValidEntry).value;
    expect(value.amount.minorUnits, 1000);
    expect(value.categoryId, 'builtin.food-drinks');
  });

  test('requires an explicit active category', () {
    final missing =
        EntryValidator.validate(draft(categoryId: null), today, activeCategories);
    expect(missing, isA<InvalidEntry>());
    expect((missing as InvalidEntry).fieldErrors['category'], isNotNull);

    final archived = EntryValidator.validate(
      draft(categoryId: 'builtin.archived'),
      today,
      activeCategories,
    );
    expect(archived, isA<InvalidEntry>());
  });

  test('accepts today and yesterday but rejects tomorrow', () {
    expect(
      EntryValidator.validate(draft(date: today), today, activeCategories),
      isA<ValidEntry>(),
    );
    expect(
      EntryValidator.validate(
        draft(date: LocalDate(2026, 11, 7)),
        today,
        activeCategories,
      ),
      isA<ValidEntry>(),
    );
    expect(
      EntryValidator.validate(
        draft(date: LocalDate(2026, 11, 9)),
        today,
        activeCategories,
      ),
      isA<InvalidEntry>(),
    );
  });

  test('rejects invalid amount boundaries', () {
    for (final amount in ['', '0.00', '999999999.01', '1.001', '1,000']) {
      final result = EntryValidator.validate(
        draft(amount: amount),
        today,
        activeCategories,
      );
      expect(result, isA<InvalidEntry>(), reason: amount);
      expect((result as InvalidEntry).fieldErrors['amount'], isNotNull);
    }
    expect(
      EntryValidator.validate(draft(amount: '0.01'), today, activeCategories),
      isA<ValidEntry>(),
    );
    expect(
      EntryValidator.validate(
        draft(amount: '999999999.00'),
        today,
        activeCategories,
      ),
      isA<ValidEntry>(),
    );
  });

  test('accepts 200 graphemes and rejects 201', () {
    expect(
      EntryValidator.validate(draft(note: 'a' * 200), today, activeCategories),
      isA<ValidEntry>(),
    );
    final tooLong = EntryValidator.validate(
      draft(note: 'a' * 201),
      today,
      activeCategories,
    );
    expect(tooLong, isA<InvalidEntry>());
    expect((tooLong as InvalidEntry).fieldErrors['note'], isNotNull);
  });

  test('dirty comparison treats restored original values as unchanged', () {
    final initial = draft();
    final changed = initial.copyWith(amountText: '20.00');
    expect(changed.sameValuesAs(initial), isFalse);
    expect(changed.copyWith(amountText: '10.00').sameValuesAs(initial), isTrue);
  });
}
