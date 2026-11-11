import 'package:flutter/material.dart';

import '../../../core/presentation/category_icon.dart';
import '../../../core/presentation/money_text.dart';
import '../domain/expense.dart';

/// Shared expense row used by Overview and History.
class ExpenseListRow extends StatelessWidget {
  const ExpenseListRow({
    super.key,
    required this.expense,
    required this.onTap,
  });

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('expense_${expense.id.value}'),
      leading: CircleAvatar(
        child: Icon(iconForCategory(expense.category.iconKey)),
      ),
      title: Text(expense.category.name),
      subtitle: Text(expense.note?.text ?? expense.category.name),
      trailing: Text(
        MoneyText.format(expense.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}
