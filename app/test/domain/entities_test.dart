import 'package:expense_tracker/core/domain/local_date.dart';
import 'package:expense_tracker/core/domain/money.dart';
import 'package:expense_tracker/features/record_expenses/domain/submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    test('blank and whitespace-only input canonicalize to no note', () {
      expect(Note.canonical(''), isNull);
      expect(Note.canonical('   \n\t '), isNull);
    });

    test('nonblank text preserves spaces and line breaks exactly', () {
      final note = Note.canonical('  Lunch\nwith team  ');
      expect(note, isNotNull);
      expect(note!.text, '  Lunch\nwith team  ');
      expect(note.isValid, isTrue);
    });

    test('counts extended grapheme clusters at the 200 boundary', () {
      final accepted = Note.canonical('a' * 200);
      final rejected = Note.canonical('a' * 201);
      expect(accepted!.isValid, isTrue);
      expect(rejected!.isValid, isFalse);

      expect(Note.canonical('👨‍👩‍👧‍👦')!.graphemeLength, 1);
      expect(Note.canonical('🇵🇰')!.graphemeLength, 1);
      expect(Note.canonical('👍🏽')!.graphemeLength, 1);
      expect(Note.canonical('e\u0301')!.graphemeLength, 1);
    });

    test('rejects 201 graphemes without truncation', () {
      final text = 'a' * 200 + '👨‍👩‍👧‍👦';
      final note = Note.canonical(text)!;
      expect(note.graphemeLength, 201);
      expect(note.isValid, isFalse);
      expect(note.text, text);
    });
  });

  group('ImmutableSubmission', () {
    test('identity is not derived from field values', () {
      final first = ImmutableSubmission(
        id: const ExpenseId('id-1'),
        amount: Money.parse('10.00').value!,
        categoryId: 'builtin.food-drinks',
        date: LocalDate(2026, 11, 8),
        note: Note.canonical('Lunch'),
      );
      final second = ImmutableSubmission(
        id: const ExpenseId('id-2'),
        amount: Money.parse('10.00').value!,
        categoryId: 'builtin.food-drinks',
        date: LocalDate(2026, 11, 8),
        note: Note.canonical('Lunch'),
      );

      expect(first.samePayload(second), isFalse);
      expect(
        first.samePayload(
          ImmutableSubmission(
            id: const ExpenseId('id-1'),
            amount: Money.parse('10.00').value!,
            categoryId: 'builtin.food-drinks',
            date: LocalDate(2026, 11, 8),
            note: Note.canonical('Lunch'),
          ),
        ),
        isTrue,
      );
    });
  });
}
