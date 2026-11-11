import 'package:flutter/material.dart';

import '../../record_expenses/domain/category.dart';
import '../domain/category_filter.dart';

/// Visible category filter covering active and archived categories.
class HistoryFilterControl extends StatelessWidget {
  const HistoryFilterControl({
    super.key,
    required this.categories,
    required this.filter,
    required this.onSelected,
    required this.onClear,
  });

  static const String _allValue = '__all_categories__';

  final List<Category> categories;
  final CategoryFilter filter;
  final ValueChanged<CategoryFilter> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = filter is SelectedCategory;
    final selectedId =
        active ? (filter as SelectedCategory).categoryId : _allValue;
    final selectedExists =
        selectedId == _allValue || categories.any((c) => c.id == selectedId);
    final activeName = active ? _nameFor(selectedId) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Category filter',
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedExists ? selectedId : _allValue,
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: _allValue,
                  child: Text('All categories'),
                ),
                for (final category in categories)
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(
                      category.isActive
                          ? category.name
                          : '${category.name} (archived)',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                if (value == _allValue) {
                  onClear();
                } else {
                  onSelected(SelectedCategory(value));
                }
              },
            ),
          ),
        ),
        if (active && activeName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtered by $activeName',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear filter'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _nameFor(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.isActive
            ? category.name
            : '${category.name} (archived)';
      }
    }
    return 'selected category';
  }
}
