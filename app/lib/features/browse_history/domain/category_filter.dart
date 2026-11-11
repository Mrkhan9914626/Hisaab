import '../../record_expenses/domain/category.dart';

/// The category filter for a history selection.
sealed class CategoryFilter {
  const CategoryFilter();

  bool get isAll => this is AllCategories;

  /// Resolves the selected category against [categories].
  ///
  /// Returns `null` for `AllCategories` or when a selected id no longer
  /// resolves. Callers must treat an unresolved selected id as a typed
  /// integrity failure, never as an empty filter result.
  Category? resolveIn(List<Category> categories) {
    final self = this;
    if (self is! SelectedCategory) {
      return null;
    }
    for (final category in categories) {
      if (category.id == self.categoryId) {
        return category;
      }
    }
    return null;
  }
}

final class AllCategories extends CategoryFilter {
  const AllCategories();
}

final class SelectedCategory extends CategoryFilter {
  const SelectedCategory(this.categoryId);

  final String categoryId;

  @override
  bool operator ==(Object other) =>
      other is SelectedCategory && other.categoryId == categoryId;

  @override
  int get hashCode => categoryId.hashCode;
}
