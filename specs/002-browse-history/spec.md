# Feature Specification: Browse and filter spending history

**Feature Branch**: `002-browse-history`  
**Created**: 2026-11-09  
**Status**: Draft — ready for planning review; no blocking clarification markers remain  
**Input**: User description: "Lets write specs for the second feature of @docs/expense-tracker-feature-map.md. For visuals designing of screen follow @docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md"

## Clarifications

### Session 2026-11-09

- Q: When the device clock is moved backward, some saved expenses can be dated later than the current period. Should forward navigation expose those saved records? → A: Yes — allow forward navigation up to the latest saved expense period so saved records remain reachable, while keeping new future-dated entries unavailable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse a period with trustworthy totals and grouped entries (Priority: P1)

As a person reviewing past spending, I want to browse a day, week, or month and see the matching entries grouped by date with accurate subtotals and a period total so that I can understand where the money went.

**Why this priority**: Without reliable period browsing and totals, the saved history cannot be understood at all. This is the core outcome of the feature.

**Independent Test**: Supply known expenses across day, week, month, and year boundaries as controlled test data, open History, and compare every displayed range, date group, subtotal, count, and total with the known records. No category-management, edit, or deletion interface is needed.

**Acceptance Scenarios**:

1. **Given** known expenses on several local calendar dates, **When** Day is selected for one date, **Then** History shows exactly that date's entries, the matching count, the date-group subtotal, and the period total, with no entry from an adjacent date.
2. **Given** expenses on the Monday and Sunday of a week and on the days immediately before and after that week, **When** Week is selected for a date inside that week, **Then** the Monday-through-Sunday records are included exactly once, the adjacent days are excluded, and the count and total match those records.
3. **Given** expenses on the first and last day of a month and in the adjacent months, **When** Month is selected for that month, **Then** the first-through-last-day records are included, the adjacent months are excluded, and the count and total match those records.
4. **Given** a selected period with entries in several date groups, **When** it is displayed, **Then** each date group has a subtotal derived from its own entries, every entry appears exactly once, and all group subtotals plus the period total agree with the same record set.
5. **Given** a displayed period, **When** previous or next is used, **Then** the selected position moves by exactly one day, week, or month for the active range, the period label and all data update together, backward navigation stops at the earliest representable date, and forward navigation stops at the later of the current period or the latest saved-expense period.
6. **Given** Month is selected on a past month, **When** the person changes the range to Week, **Then** the current week is selected rather than the week containing the old month's position; the same current-period reset applies to every range change.
7. **Given** a displayed period, **When** a row is opened and then closed, **Then** read-only details appear and Back returns to History with the same range, period, and filter still selected.
8. **Given** saved expenses dated after the device's current local date because the device clock was moved backward, **When** the person navigates forward from the current period, **Then** those saved periods are reachable and show their exact rows, counts, and totals, while creating a new future-dated expense remains unavailable.

---

### User Story 2 - Filter by category without breaking the totals (Priority: P1)

As a person reviewing spending, I want to filter a selected period by any category, including an archived one, and see the list, count, and totals narrow together so that I can trust the filtered result.

**Why this priority**: The feature promises category-filtered history; a filter that disagrees with the totals or hides historical categories would make the result untrustworthy.

**Independent Test**: Supply records for multiple active and archived categories in a known period, apply each filter, and compare the displayed rows, date subtotals, count, and period total with the expected subset. Clearing the filter must restore the full result.

**Acceptance Scenarios**:

1. **Given** no filter applied, **When** History opens, **Then** All categories is visibly selected and the full selected-period result is shown.
2. **Given** records in several categories, **When** an active category is selected, **Then** only that category's records remain, and the count, date subtotals, and period total all change together to match that subset.
3. **Given** an archived category with earlier expenses, **When** it is selected in the History filter, **Then** its historical entries, count, and totals appear even though the category cannot be chosen for new entries.
4. **Given** an active category filter, **When** the person clears the filter, **Then** the full unfiltered selected-period result returns and the filter no longer appears active.
5. **Given** a filter that matches no records in the selected period, **When** the result is shown, **Then** the total and count are zero, the message says no entries match the filter, and a clear-filter action is offered without claiming the data is unavailable or that no expenses exist.
6. **Given** an active filter, **When** the period changes, **Then** the filter remains visibly active and the new period's rows, count, and totals reflect the same category selection.

---

### User Story 3 - Understand empty periods and honest load failures (Priority: P2)

As a person browsing history, I want empty periods and unavailable data to be clearly different so that I never mistake a failed read for a period with no spending.

**Why this priority**: A local-only tracker cannot recover lost or misreported history elsewhere; an empty-looking screen after a failure would destroy trust.

**Independent Test**: Exercise a confirmed empty period, an empty filter result, a store with no expenses at all, and controlled read failures, and inspect the message, totals, available actions, and retry behavior.

**Acceptance Scenarios**:

1. **Given** expenses exist in other periods but none in the selected period, **When** the period is displayed, **Then** the total and count are zero, the message says the selected period is empty, and Go to today plus normal period navigation are offered; it does not say No expenses yet or claim the data is unavailable.
2. **Given** a selected day with no expenses, **When** the empty period is displayed, **Then** an action to add an expense for that selected day is offered in addition to Go to today.
3. **Given** a store with no expenses ever recorded, **When** History opens, **Then** an empty-history invitation to add the first expense is shown with zero totals, without registration, onboarding, or an unavailability claim.
4. **Given** a read failure for the selected period or filter, **When** the result cannot be loaded, **Then** an actionable error and Retry appear instead of zero totals or an empty-period message, and saved data is not reset, replaced, or deleted.
5. **Given** a read failure followed by Retry, **When** the retry succeeds, **Then** the previously selected range, period, and filter are preserved and the correct records appear.
6. **Given** previously loaded values are shown while a refresh fails, **When** the failure occurs, **Then** the retained values are explicitly marked unavailable or stale rather than presented as current.

---

### User Story 4 - Start an expense from History with the right date (Priority: P2)

As a person browsing a day's history, I want to start a new expense for that day and return to the history view with updated results so that adding a missed expense fits the browsing journey.

**Why this priority**: The selected-day shortcut is useful only if it never leaks a stale date into unrelated entries and never makes an out-of-range save look like part of the current result.

**Independent Test**: Start Add expense from Day, Week, and Month history contexts, inspect the prefilled date, save into and outside the displayed period and filter, and verify the return destination, success feedback, and refreshed results.

**Acceptance Scenarios**:

1. **Given** Day history is showing a selected date, **When** Add expense is started from History, **Then** that selected date is prefilled in the form.
2. **Given** Week or Month history is showing, **When** Add expense is started from History, **Then** the form defaults to today rather than the period start or any earlier selected day.
3. **Given** Add expense was started from a selected day and completed or abandoned, **When** a later unrelated new expense is started, **Then** the earlier selected day is not reused and the new form uses today.
4. **Given** a save originating from History succeeds with a date and category inside the displayed period and filter, **When** the app returns, **Then** it returns to History with success feedback and the refreshed view includes the new entry, count, and totals.
5. **Given** a save originating from History succeeds with a date or category outside the displayed period or filter, **When** the app returns, **Then** success is communicated without implying the entry belongs to the current result, and the current rows and totals remain correct for the actual selection.
6. **Given** a save originating from History fails, **When** the failure is reported, **Then** the entered form, retry, duplicate-submit protection, and discard confirmation follow the recording feature's rules and no success is shown.

### Edge Cases

- Period boundaries include leap days, month lengths, year transitions, weeks spanning two months or years, and a month containing a week boundary. Each record is included exactly once and adjacent periods never overlap.
- Week behavior is Monday through Sunday using local calendar dates. A week spanning a month or year boundary includes all its days; the week containing the selected date is selected.
- Device timezone or clock changes must not rewrite saved expense dates or silently move a saved record into or out of a selected period. Period membership compares civil calendar dates, not elapsed time or UTC instants.
- The earliest representable date and the latest reachable period are navigation limits: backward navigation stops at the earliest valid local date, and forward navigation stops at the latest of the current period or the latest saved expense period. Saved records that become later than the current date after a device-clock rollback remain reachable, while new future-dated entries remain unavailable. A stale or clock-shifted selected period does not rewrite saved dates.
- Exactly-once totals hold when the selected period contains many entries, repeated identical amounts, or totals that exceed the per-expense maximum. Totals remain exact and never wrap, round, or truncate.
- An archived category containing expenses remains filterable after archiving and after restart; an archived category with no expenses may be absent from results without error. No archiving, restoration, rename, reassignment, or deletion is performed by History.
- A selected period remains stable when local midnight passes while History is open; Go to today moves to the current period. Reopening History starts at the current day.
- Empty period, empty filter result, no expenses ever, and read failure produce four distinct, non-interchangeable states with zero-or-unavailable totals handled honestly.
- A save made while a filter is active or while a non-matching period is selected must not cause the entry to disappear from the saved history or appear falsely in the current result.
- Very long category names or notes, large system text, landscape, the keyboard, reduced motion, and both light and dark themes must not hide range controls, the filter, totals, rows, empty actions, or retry actions.
- A selected period with hundreds of grouped entries must remain fully scrollable; no entry in the selected record set may be omitted to make the list shorter.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The person MUST be able to open History from Overview, browse saved spending, open a row's read-only details, and return to the same History view entirely offline on Android, without registration, account, or network dependency.
- **FR-002**: History MUST provide labeled Day, Week, and Month range controls. Each selection MUST display a readable label naming the covered local calendar period and indicating when it is the current period. A freshly opened History MUST default to the current local day.
- **FR-003**: Previous and next navigation MUST move the selected position by exactly one day for Day, one week for Week, and one calendar month for Month. Forward navigation MUST stop at the latest of the current period or the latest period containing a saved expense, so records that become later than the current date after a device-clock rollback stay reachable, while creating new future-dated expenses remains unavailable. Backward navigation MUST stop at the earliest representable local date. The period label, rows, count, and totals MUST update together.
- **FR-004**: Changing the range type MUST reset the selected position to the current period of the newly selected range — the current day, current week, or current month — rather than carrying the previous position forward.
- **FR-005**: History MUST show the selected period's exact total and expense count together with entries grouped by local calendar date and a subtotal for each date group. The total, count, date subtotals, and displayed rows MUST all derive from the same selected record set identified by the selected period and active filter, and each record MUST appear exactly once.
- **FR-006**: Date groups MUST be ordered newest date first, entries within a date group MUST be ordered newest-saved first with a stable order, and every group MUST show a readable local date label and its subtotal. Display order MUST NOT change the calculated totals.
- **FR-007**: Each history row MUST show the category icon, the note or a category-name fallback, the category label, and the PKR amount, and MUST open the read-only details for that expense. Back from details MUST return to History with the same range, period, and filter selected.
- **FR-008**: History MUST expose a visible category filter containing All categories, every active category, and every archived category, so historical categories remain selectable after archiving. The active filter MUST be visibly identified, and a clear-filter action MUST be available without relying on color, icons, hover, or gestures alone.
- **FR-009**: Selecting a category MUST narrow the rows, count, date subtotals, and period total together to that category's records within the selected period. Clearing the filter MUST restore the full period result. An active filter MUST remain visible across period navigation, range-type changes, and detail round trips and MUST NOT silently clear.
- **FR-010**: Period boundaries MUST use local calendar dates: Day covers the selected date inclusively; Week covers Monday through Sunday inclusively for the week containing the selected date; Month covers the first through last day of the selected local month inclusively. Ranges MUST be non-overlapping and inclusive at their boundaries, MUST NOT be derived from UTC instants, and MUST NOT shift a saved expense to another date after a timezone change.
- **FR-011**: All displayed money MUST use exact PKR arithmetic with the recording feature's formatting and at most two fractional digits. Filtered totals, date subtotals, and counts MUST remain exact, including totals that exceed the per-expense maximum; no value may be silently rounded, truncated, wrapped, or replaced with a plausible incorrect amount.
- **FR-012**: When the selected period has no records but expenses exist elsewhere, History MUST show zero totals and count, state that the selected period is empty, offer Go to today, and — when a specific day is selected — offer adding an expense for that day. It MUST NOT show No expenses yet or imply that data is unavailable.
- **FR-013**: When an active filter matches no records in the selected period, History MUST show zero totals and count, state that no entries match the filter, and offer a clear-filter action. It MUST NOT imply that records are missing, unavailable, or that no expenses exist at all.
- **FR-014**: When the store contains no expenses at all, History MUST show an empty-history state inviting the first expense with zero totals and a working add action, without a registration or mandatory onboarding flow.
- **FR-015**: Go to today MUST select the current local period for the active range type — today for Day, the current week for Week, the current month for Month — and refresh the data while preserving any explicitly active filter.
- **FR-016**: A failed History load MUST show an actionable error and Retry that are clearly distinct from an empty or no-match result. It MUST NOT display zero totals as if no records existed, silently reset or replace stored data, or present stale values as current without marking them unavailable. Retry MUST use the same saved data and preserve the selected range, period, and filter.
- **FR-017**: Starting Add expense from History MUST default the form date to the selected day when Day is active, and otherwise to today. A Week or Month context, or a later unrelated new entry, MUST NOT inherit a stale selected-day date. After a successful save originating from History, the app MUST return to History with success feedback and refresh the current view; if the saved date or category falls outside the displayed period or filter, the app MUST NOT imply that the entry belongs to the current result.
- **FR-018**: History MUST consume the recording feature's shared contracts — stable expense identity, exact PKR amount, local calendar expense date, optional note, and stable category identity with active or archived status — without redefining them. History MUST NOT rename, reassign, archive, restore, delete, or otherwise mutate saved expenses or categories.
- **FR-019**: A reported History read MUST reflect durably saved records that survive app termination and restart. History MUST reflect successful saves, edits, or deletions made through other features when the view is refreshed, MUST leave saved data unchanged on read failure, and MUST preserve records, relationships, dates, and amounts across any versioned storage change; an unsupported storage state MUST produce an explicit error rather than a reset.
- **FR-020**: Navigation MUST expose working Overview-to-History, History-to-details, and History-to-Add-expense journeys. History MUST NOT offer inert or simulated Edit, Delete, Categories, Settings, or appearance controls; those arrive with their owning features.
- **FR-021**: History MUST follow the approved visual direction in both light and dark themes and meet accessible interaction: visible labels, selected and pressed states exposed to screen readers, normal-text contrast of at least 4.5:1, large-text and meaningful non-text contrast of at least 3:1, Android touch targets of at least 48 dp, system text scaling, reduced motion, keyboard-open and safe-area handling, and predictable native Back behavior. Essential operations MUST NOT rely on color, icons, hover, or swipe alone.
- **FR-022**: History MUST remain responsive for the local dataset defined in SC-002: changing range or filter, navigating periods, and opening a period MUST present correct grouped results within the targets in Success Criteria, and every entry in the selected record set MUST remain reachable by scrolling without truncation.
- **FR-023**: History data MUST remain in app-private device storage and MUST NOT be transmitted to remote services. Diagnostics MUST exclude expense amounts, dates, notes, category names, user identifiers, and stored financial contents, and no account, cloud, backup, or restore controls may be introduced.

### Constitution Alignment *(mandatory)*

Authority: [Constitution v2.0.0](../../.specify/memory/constitution.md). The [feature map](../../docs/expense-tracker-feature-map.md#feature-2--browse-and-filter-spending-history) supplies boundaries; the [approved screen direction](../../docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md) guides presentation. Proposed screen defaults are not treated as approved solely because the visual direction was approved; the week-start decision is resolved explicitly below.

- **Scope / Principle V**: FR-001–023 deliver the second V1 slice only, on Android, with PKR-only money and no income, budgets, balances, receipt scanning, bank integration, other currencies, accounts, cloud synchronization, or backup/restore. This is not the complete V1 release and adds no category lifecycle, expense maintenance, or Settings/appearance UI.
- **Privacy/offline / Principle I**: FR-001, FR-023, and the shared recording contract require fully offline history, app-private storage, non-sensitive diagnostics, packaged offline assets, and no remote financial transfer. History performs no new network activity and introduces no telemetry.
- **Correctness / Principle II**: FR-005–011 and FR-022 define exact PKR arithmetic, consistent filtered totals and counts, unambiguous inclusive day/week/month boundaries, Monday-through-Sunday weeks, and local civil dates that survive timezone changes. The week start is an explicit specification decision, not an inference from visual approval.
- **Data safety / Principle III**: FR-007, FR-016, and FR-018–019 require durable reads, no mutation of saved records, archived categories that remain readable and filterable, honest read-failure handling, restart persistence, and non-destructive versioned storage changes. History never deletes, reassigns, or resets saved data.
- **Accessibility / Principle IV**: FR-002–003, FR-007–009, FR-021, and the empty/failure states require Android labels, exposed selected states, contrast, 48 dp targets, screen-reader order, large text, reduced motion, keyboard/safe-area handling, and Back behavior that does not lose the current selection.
- **Verification / Principle V**: Every numbered acceptance scenario, edge case, requirement, and success criterion MUST map to source-level review, a successful Android build, or a named manual Android inspection. Automated test authoring is not required and MUST NOT block completion. Native offline checks must identify physical-device versus emulator evidence and disclose skipped checks; browser-prototype behavior is not acceptance evidence.

### Scope and Unresolved Decisions *(mandatory)*

**Included**: Working Overview-to-History navigation; Day/Week/Month browsing with previous/next; readable period labels; exact period totals and counts; date-grouped entries with subtotals; category filtering including archived categories; clear-filter behavior; row-to-details navigation; honest empty-period, no-match, no-expenses-ever, stale, and read-failure states; Go to today; selected-day Add integration and return-to-History refresh; and accessible light/dark presentation.

**Excluded**: Expense creation rules beyond the integration described (owned by the recording feature); expense editing and deletion; category creation, rename, archive, restore, or deletion; Settings and manual appearance selection; arbitrary date pickers not shown in the approved direction; income, budgets, balances/savings metrics, charts, receipt scanning, bank integration, other currencies, accounts, cloud sync, and manual backup/restore. No inert controls for excluded features may be added.

**Resolved specification decisions — 2026-11-09**:

- **Week start**: Weeks run Monday through Sunday inclusive, using the device's local calendar. This adopts the screen study's proposed default and fixes it for this feature as a specification decision, not as an approval inferred from the visual design.
- **Fresh History default**: Day showing the current local day.
- **Forward limit**: Forward navigation stops at the latest of the current period or the latest saved expense period, so saved history cannot be hidden by a device-clock rollback; creating new future-dated expenses remains unavailable.
- **Ordering**: Date groups newest first; entries within a date newest-saved first, with stable ordering. Totals are independent of order.
- **Midnight and restart**: An already-selected period does not silently change at midnight; reopening History starts at the current day.
- **Filter behavior**: All known active and archived categories are available; an active filter persists across period navigation, range-type changes, and detail round trips and remains visibly clearable.
- **Go to today**: Selects the current period for the active range type and preserves any active filter.
- **Add context**: Selected-day prefill only while Day is active; Week, Month, and later unrelated entries default to today.

**Proposed defaults distinguished from approved requirements**: The screen study proposed Monday-through-Sunday weeks; this specification now adopts that rule explicitly rather than treating it as approved through the visual review. The recording feature's confirmed performance baseline — an Android phone from 2020–2022 with 4 GB memory and 10,000 expenses over 24 months, including 500 today — is reused and restated in SC-002; the numeric targets in Success Criteria are binding acceptance targets, not measured results. No framework, persistence tool, or architecture is selected here; the owner-approved stack and minimum Android version are handled in planning.

**Unresolved decisions**: None block this specification. Field limits, note limits, future-date rules, and category naming belong to the recording and category features and are consumed, not redefined. Consequential implementation choices remain planning gates.

**Dependencies and approval gates**: This feature depends on the recording feature's expense/category contracts, saved-record behavior, read-only details, and Add-expense form. Archived-category filtering can be verified with fixtures before category management exists; the archive-to-filter journey becomes an integration check once that feature is available. Edit/delete totals regression depends on the maintenance feature but is not implemented here. Completing this feature does not authorize release or waive remaining V1 obligations. Any target change requires an explicit owner-approved specification amendment.

### Key Entities *(include if feature involves data)*

- **Expense**: The shared saved spending record with stable identity, exact positive PKR amount, stable category reference, local calendar expense date, and optional note. History reads it but never changes it.
- **Category**: The shared stable category identity with display name, offline icon, and active or archived status. History displays all categories as filter options; archived categories remain usable for filtering and remain attached to their saved expenses.
- **History selection**: The active range type (Day, Week, or Month), the selected anchor date, and the derived inclusive local date range. Changing the range type resets the selection to the current period of the new type.
- **Category filter**: Either All categories or one selected category identity, including archived categories. It narrows the rows, count, date subtotals, and period total to the same record set.
- **History snapshot**: The consistent view for one selection and filter, containing exact total, count, date groups with subtotals, and a status of loading, available, empty period, no filter matches, no expenses ever, or unavailable/stale.
- **Date group**: One local calendar date within the selected period, its entries, and a subtotal derived only from those entries.

## Success Criteria *(mandatory)*

### Measurable Outcomes

These are binding acceptance targets to verify during implementation, not measurements of an existing application.

- **SC-001**: In a task study with 10 people unfamiliar with the app, at least 9 can, without assistance or a network connection, select a supplied day, week, or month and a category, find a supplied entry, and state the matching period total within 30 seconds starting from Overview.
- **SC-002**: On an Android phone released during 2020–2022 with 4 GB memory, at least 1 GB free device storage, a supported OS version, and no network connection, using 10,000 saved expenses spanning 24 months with 500 dated today across the six built-in categories, over 30 offline trials, at least 29 selected-period loads show correct grouped entries, count, and total within 2 seconds; at least 29 range-type changes or category-filter changes show correct results within 500 milliseconds; and at least 29 history-row selections show correct details within 500 milliseconds.
- **SC-003**: Across all day, week, month, leap-day, and year-boundary fixtures, 100% of displayed entries, counts, date subtotals, and period totals match the expected saved records exactly, every entry appears exactly once, and no timezone change or device-clock rollback moves a saved expense between dates or periods or hides a saved record from navigation.
- **SC-004**: Across at least 100 active-category and archived-category filter trials, 100% of filtered rows, counts, date subtotals, and totals match the expected subset; clearing a filter restores the full result in 100% of trials; and no expense attached to an archived category becomes inaccessible.
- **SC-005**: Across every controlled empty-period, no-match, no-expenses-ever, stale-data, and read-failure test, 100% show the correct distinct state with either zero totals or an explicit unavailable state, an appropriate action, and no false-empty, false-success, silent reset, or lost saved record.
- **SC-006**: Across the selected-day, Week/Month, related-save, out-of-range-save, and unrelated-next-entry trials, 100% prefill the correct date, return to History with correct success feedback, and refresh rows, counts, and totals without falsely including an out-of-range entry.
- **SC-007**: On Android offline, 100% of the History journeys pass a source review, a successful build, and manual inspection of restart persistence, light/dark contrast, 48 dp targets, screen-reader labels and order, 200% text or the platform maximum if lower, reduced motion, keyboard-open, landscape, and safe areas with zero blocked essential actions. The required offline and accessibility evidence must state whether it used a physical device or an emulator.
