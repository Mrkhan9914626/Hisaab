import '../../../core/domain/local_date.dart';
import '../../../core/domain/money.dart';
import 'category.dart';
import 'submission.dart';

class Expense {
  const Expense({
    required this.id,
    required this.saveSequence,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });

  final ExpenseId id;
  final int saveSequence;
  final Money amount;
  final Category category;
  final LocalDate date;
  final Note? note;

  bool matchesSubmission(ImmutableSubmission submission) =>
      id == submission.id &&
      amount == submission.amount &&
      category.id == submission.categoryId &&
      date == submission.date &&
      note == submission.note;
}
