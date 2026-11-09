import 'package:flutter/material.dart';

enum DiscardChoice {
  keepEditing,
  discard,
}

Future<DiscardChoice> showDiscardExpenseDialog(BuildContext context) async {
  final choice = await showDialog<DiscardChoice>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text('Discard expense changes?'),
      content: const Text(
        'Your unsaved amount, category, date and note will be lost. '
        'Saved expenses are not affected.',
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(DiscardChoice.keepEditing),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DiscardChoice.discard),
          child: const Text('Discard changes'),
        ),
      ],
    ),
  );
  return choice ?? DiscardChoice.keepEditing;
}

Future<bool> showCancelPendingSaveDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text('Cancel saving this expense?'),
      content: const Text(
        'If the expense has already been stored, it will stay saved. '
        'Otherwise the pending save will be cancelled.',
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep waiting'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancel save'),
        ),
      ],
    ),
  );
  return result ?? false;
}
