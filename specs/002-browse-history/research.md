# Research: Offline history browsing on the Feature 1 stack

**Feature:** `002-browse-history` | **Date:** 2026-11-09  
**Status:** Decisions complete; no build, SDK command, database query or device inspection was executed during planning.

## 1. Stack, platform and dependency reuse

**Decision:** Reuse the Feature 1 technology stack exactly: Flutter with its bundled Dart, SQLite through `sqflite 2.4.5`, `characters 1.4.1`, `uuid 4.6.0`, development-only `sqflite_common_ffi 2.4.5` and `flutter_lints 5.0.0`, Codemagic cloud builds, and Android 7.0 / API 24 minimum. Keep the candidate Flutter `3.47.8` pin and the same bootstrap/lockfile verification gate. Add **no new production dependency**. Target Android only under Constitution v2.0.0; Feature 1's iOS artifacts are legacy and out of scope.

**Rationale:** The owner selected this stack for Feature 1 and the constitution records it as owner-approved. History is a read-oriented UI slice that needs no new library: SDK widgets, `ChangeNotifier`, `Navigator` and constructor injection already cover the required interaction. Keeping the same pins avoids a second toolchain decision and keeps builds reproducible.

**Alternatives considered:** A calendar/date-range package adds a dependency for arithmetic that is small, exact and testable with `LocalDate`. `intl` would add locale data and formatting policy beyond the scope. A router or state-management package is unnecessary for one pushed screen. A second SQLite adapter or ORM would contradict the one-owner storage contract. Adding iOS work would violate the current Android-only constitution.

**Sources:** Feature 1 [plan](../001-record-expenses/plan.md) and [research](../001-record-expenses/research.md); [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms); [sqflite](https://pub.dev/packages/sqflite); [Codemagic Flutter setup](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/).

## 2. Civil-date period arithmetic and Monday–Sunday weeks

**Decision:** Represent every selection as a range type plus an anchor `LocalDate`. Derive an inclusive `HistoryPeriod` using pure calendar arithmetic:

- **Day**: the anchor date only.
- **Week**: Monday through Sunday of the calendar week containing the anchor; compute the Monday by subtracting `(weekday - 1)` days and the Sunday by adding 6 days.
- **Month**: first through last day of the anchor's month.

Previous/next move exactly one day, one week or one calendar month. Month navigation clamps to a valid day so a 31st never normalizes into the next month. Periods are compared as civil dates (`YYYY-MM-DD` strings or `LocalDate`), never as UTC instants or elapsed durations. The representable domain is `0001-01-01`–`9999-12-31`; year-10000 boundaries are avoided with inclusive predicates.

**Rationale:** The specification fixes Monday–Sunday weeks and local calendar membership. Pure arithmetic is independent of widgets and SQL, reviewable against leap-day, month-length and year-boundary fixtures, and immune to timezone changes. Fixed-width civil strings sort chronologically over the supported domain.

**Alternatives considered:** `DateTime.add(Duration(days: ...))` crosses daylight-saving transitions and is not a civil-date operation. UTC conversion moves saved dates after timezone changes. A package-based week definition can differ by locale and is not needed because the product fixes Monday. Constructing the first day of year 10000 would leave the valid domain; use `<= '9999-12-31'` instead.

**Sources:** Feature 1 [data model §Value objects](../001-record-expenses/data-model.md); [Dart DateTime](https://api.dart.dev/dart-core/DateTime-class.html); [SQLite date functions](https://sqlite.org/lang_datefunc.html).

## 3. Single-snapshot history reads and exact totals

**Decision:** The existing `ExpenseRepository` gains read-only history methods. One transaction returns:

1. all joined expense rows for the inclusive period, optionally filtered by `category_id`, ordered `expense_date DESC, save_sequence DESC`;
2. `EXISTS(SELECT 1 FROM expenses)` for the no-expenses-ever distinction;
3. `MAX(expense_date)` for the forward navigation limit.

Date groups, group subtotals, count and period total are derived in pure Dart from exactly the returned rows, using checked `BigInt` accumulation mapped to signed 64-bit integers. SQL uses `SUM` nowhere in the history path, so a displayed total cannot disagree with displayed rows. A storage or overflow failure is a typed failure, never a zero-filled snapshot.

**Rationale:** Constitution II requires list, count, subtotals and total to come from the same record set. One transaction and one row list make that true by construction. Integer paisa keeps exactness; checked accumulation handles totals beyond one expense's maximum. The existing `(expense_date, save_sequence DESC)` index supports the range scan and required ordering.

**Alternatives considered:** Separate count/sum/group queries can interleave with a concurrent write and disagree. SQL `total()` or casting to `REAL` loses exactness. Persisting summary caches creates a second financial truth. Filtering after loading the whole store would waste memory and break the performance target. Adding a new index or schema version is not justified before measurement; a plain range scan over the indexed 10,000-row acceptance fixture is small.

**Sources:** Feature 1 [persistence contract](../001-record-expenses/contracts/persistence.md); [SQLite aggregate functions](https://sqlite.org/lang_aggfunc.html); [SQLite query planner/indexes](https://sqlite.org/optoverview.html); [Dart integers](https://dart.dev/language/built-in-types).

## 4. Navigation limits and device-clock rollback

**Decision:** Backward navigation stops at the period containing `0001-01-01` for the active range. Forward navigation stops at the **later** of:

- the current period for the active range, and
- the period containing `MAX(expense_date)`.

Thus, after a device-clock rollback, saved periods later than the current date remain reachable and show their exact records, while the Add-expense form still rejects new future-dated entries. Range-type changes and Go to today select the current period of the active range, not the period containing the old anchor. The controller computes bounds from the latest loaded snapshot and refreshes them on reload/resume.

**Rationale:** This is the explicit 2026-11-09 clarification and the only rule that both preserves reachable history and keeps future entry creation disabled. Computing the limit from saved data rather than the clock alone prevents valid records from becoming invisible.

**Alternatives considered:** Stopping strictly at the current period hides saved records after clock rollback, violating the clarification. Allowing unlimited forward navigation exposes periods with no saved data while future entry remains blocked and confuses the model. Rewriting saved dates on clock change would violate civil-date identity and data safety.

**Sources:** Feature 2 [spec §Clarifications, FR-003, Edge Cases](spec.md); Feature 1 [data model](../001-record-expenses/data-model.md) (civil dates are never rewritten).

## 5. Category filtering including archived categories

**Decision:** Add `listCategoriesForFilter()` returning all categories ordered by their stable seed/row order, whether active or archived, with name, icon key and active flag. The filter value is either `All categories` or one category id. The same read transaction applies the optional `category_id` predicate before deriving groups/count/total. Archived categories remain selectable and their saved rows display the current category name/icon. History performs no archive, restore, rename or reassignment.

**Rationale:** The specification requires historical categories to remain filterable after archiving. A separate "active-only" list would silently drop valid historical filters. Using the joined current category metadata keeps rows readable without mutating stored references.

**Alternatives considered:** Reusing `listActiveCategories()` would exclude archived categories. Filtering by category name is ambiguous after rename; stable ids are required. Client-side filtering after loading all periods would not scale and could disagree with totals.

**Sources:** Feature 1 [local operations contract](../001-record-expenses/contracts/local-operations.md); Feature 2 [FR-008, FR-009, FR-018](spec.md); `app/lib/core/storage/migrations.dart` (stable ids and `is_active`).

## 6. Overview → History navigation and Add-expense prefill

**Decision:** Overview exposes one clearly labeled History action that pushes the new History screen. History pushes the existing read-only details screen and the existing Add-expense screen. `AddExpenseScreen` and `EntryController` accept an optional `initialDate` parameter. Only a Day-context History action supplies the selected date; Week, Month, Overview and later unrelated new-entry forms omit it and default to today. On success the Add form returns the saved `Expense` (instead of only a bool); History refreshes and shows neutral success feedback, explicitly noting when the saved date/category is outside the current period/filter.

**Rationale:** An explicit constructor input prevents a stale global "last selected day" from leaking into unrelated entries. Returning the saved record lets History distinguish in-view from out-of-view saves without implying false inclusion. Existing recording validation, cancellation and duplicate-submit rules remain untouched.

**Alternatives considered:** A mutable app-level selected-date singleton leaks state. Passing the selected date for Week/Month violates FR-017. Using the Add screen's snackbar alone cannot refresh History or state out-of-view status. Adding a second add-expense form would duplicate validation and save behavior.

**Sources:** Feature 1 [local operations](../001-record-expenses/contracts/local-operations.md), [Add expense screen](../../app/lib/features/record_expenses/presentation/add_expense_screen.dart); Feature 2 [FR-017](spec.md); approved [screen direction §4 History](../../docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md).

## 7. Presentation, accessibility and large lists

**Decision:** Reuse `AppTheme` light/dark tokens, `MoneyText`, `iconForCategory` and `StorageNotice`. Build range controls from labeled `SegmentedButton<HistoryRangeType>` (or equally labeled 48 dp controls), previous/next icon buttons with tooltips and exposed disabled state, a labeled filter dropdown/menu with archived options visibly marked, a visible active-filter description and a separate Clear filter button. Render the grouped result with a virtualized `ListView` over a flattened header/row item model so every matching record stays reachable without building the whole list eagerly. Give every empty/error state its own text, semantics and action.

**Rationale:** Constitution IV requires labels, exposed states, 4.5:1/3:1 contrast, 48 dp targets, text scaling, reduced motion, keyboard/safe-area handling and non-color-only operation. A flattened builder list keeps hundreds of grouped rows responsive while preserving all records. Reusing existing components keeps the visual direction consistent with Overview and details.

**Alternatives considered:** Icon-only range/period controls fail labeling and non-color reliance. A nested list of `ListView` per date group can be inefficient and complicates scroll reachability. Hiding long results to shorten the list violates FR-022. Introducing a new component library or font package adds dependency and licensing work without need.

**Sources:** Feature 2 [FR-021, FR-022](spec.md); Constitution IV; [Material accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility); [Flutter long lists](https://docs.flutter.dev/cookbook/lists/long-lists).

## 8. Performance and verification approach

**Decision:** Keep the Feature 1 binding baseline: 10,000 expenses over 24 months with 500 today, 2020–2022 Android phone with 4 GB memory, ≥1 GB free, offline. Use the indexed one-transaction read; measure period loads (≥29/30 ≤2 s), range/filter changes (≥29/30 ≤500 ms) and row-to-details (≥29/30 ≤500 ms). Verification is source review, a successful Android debug build, and named manual Android inspections; automated test authoring is not required and is not a completion gate. Any skipped lane or check is disclosed.

**Rationale:** Constitution V makes production source the deliverable and correctness a matter of review, build and manual checks. The numeric targets are acceptance targets to measure during implementation, not existing measurements. Reusing the Feature 1 dataset and device class keeps evidence comparable.

**Alternatives considered:** Claiming performance from a browser prototype or unmeasured assumptions is not evidence. A separate benchmark harness would add infrastructure the constitution does not require. Dropping old checks silently would misrepresent coverage.

**Sources:** Feature 2 [SC-002, SC-007](spec.md); Constitution V; Feature 1 [research §8](../001-record-expenses/research.md); [Codemagic testing](https://docs.codemagic.io/yaml-testing/testing/).

## Decision status

No unresolved product question remains. The stack is identical to Feature 1 and introduces no dependency or schema change. Remaining technical gates are the same Feature 1 bootstrap/lockfile verification, an authorized Android build, and named manual device/emulator checks including performance, accessibility and restart persistence. No build, query, benchmark or inspection result is claimed by this research.
