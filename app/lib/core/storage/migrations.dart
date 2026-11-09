import 'package:sqflite/sqflite.dart';

const List<Map<String, Object>> seedCategories = [
  {
    'id': 'builtin.food-drinks',
    'name': 'Food & drinks',
    'icon_key': 'food_drinks',
    'is_active': 1,
    'is_protected': 0,
  },
  {
    'id': 'builtin.transport',
    'name': 'Transport',
    'icon_key': 'transport',
    'is_active': 1,
    'is_protected': 0,
  },
  {
    'id': 'builtin.shopping',
    'name': 'Shopping',
    'icon_key': 'shopping',
    'is_active': 1,
    'is_protected': 0,
  },
  {
    'id': 'builtin.bills',
    'name': 'Bills',
    'icon_key': 'bills',
    'is_active': 1,
    'is_protected': 0,
  },
  {
    'id': 'builtin.health',
    'name': 'Health',
    'icon_key': 'health',
    'is_active': 1,
    'is_protected': 0,
  },
  {
    'id': 'builtin.other',
    'name': 'Other',
    'icon_key': 'other',
    'is_active': 1,
    'is_protected': 1,
  },
];

/// Creates schema v1 and seeds the six built-in categories inside the
/// transaction supplied by sqflite's `onCreate` callback.
Future<void> createSchemaV1(Database db) async {
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      icon_key TEXT NOT NULL,
      is_active INTEGER NOT NULL CHECK (is_active IN (0, 1)),
      is_protected INTEGER NOT NULL CHECK (is_protected IN (0, 1))
    )
  ''');

  await db.execute('''
    CREATE TABLE expenses (
      save_sequence INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT NOT NULL UNIQUE,
      amount_minor INTEGER NOT NULL
        CHECK (typeof(amount_minor) = 'integer'
          AND amount_minor BETWEEN 1 AND 99999999900),
      category_id TEXT NOT NULL
        REFERENCES categories (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
      expense_date TEXT NOT NULL,
      note TEXT
    )
  ''');

  await db.execute(
    'CREATE INDEX expenses_date_sequence '
    'ON expenses (expense_date, save_sequence DESC)',
  );

  await db.execute('''
    CREATE TRIGGER categories_protect_other_update
    BEFORE UPDATE ON categories
    FOR EACH ROW
    WHEN OLD.id = 'builtin.other'
      AND (NEW.id <> OLD.id
        OR NEW.name <> OLD.name
        OR NEW.is_active <> 1
        OR NEW.is_protected <> 1)
    BEGIN
      SELECT RAISE(ABORT, 'Other category is protected');
    END
  ''');

  await db.execute('''
    CREATE TRIGGER categories_protect_other_delete
    BEFORE DELETE ON categories
    FOR EACH ROW
    WHEN OLD.id = 'builtin.other'
    BEGIN
      SELECT RAISE(ABORT, 'Other category cannot be deleted');
    END
  ''');

  await db.execute('''
    CREATE TRIGGER expenses_require_active_category
    BEFORE INSERT ON expenses
    FOR EACH ROW
    WHEN (SELECT is_active FROM categories WHERE id = NEW.category_id) IS NOT 1
    BEGIN
      SELECT RAISE(ABORT, 'Expense category must be active');
    END
  ''');

  for (final category in seedCategories) {
    await db.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
