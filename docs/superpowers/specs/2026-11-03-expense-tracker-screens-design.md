# Personal Expense Tracker — Screen Design

**Status:** Screen design approved by the user on 2026-11-03. Written specification pending final review.

**Source of scope:** [Application summary](../../expense-tracker-summary.md).

**Design direction:** Quiet ledger — clear amounts, restrained teal, pale blue-gray surfaces, and fast manual entry.

## 1. Purpose and boundaries

Design a personal expense tracker for Android and iPhone. A person should be able to record an expense quickly, browse spending by day, week, or month, and organize entries using customizable categories.

Version 1 uses Pakistani rupees (PKR) only and stores expense data on the device. No account or cloud synchronization is included.

Do not introduce income tracking, budgets, balance or savings metrics, receipt scanning, bank integrations, multiple currencies, or manual backup and restore. Spending is not presented as inherently good or bad using red/green status indicators.

This specification defines the approved screen system, not a production architecture. Technology stack, database, and native implementation remain undecided. The HTML prototype is a design reference, not the application.

## 2. Navigation and screen relationships

Use three labeled primary tabs:

- **Overview:** today's spending, this month's total, and today's expenses.
- **History:** daily, weekly, and monthly browsing.
- **Categories:** customize and archive categories.

Settings is reached from the Overview header rather than occupying a fourth tab. Add expense is a prominent labeled action on Overview and History, not a navigation tab.

Secondary flows:

- Overview or History → expense details → edit expense or delete confirmation.
- Overview or History → add expense → return to the originating screen after a successful save.
- Categories → add or edit category → return to Categories after saving.
- Overview → Settings → back to Overview.

In the native app, back/cancel returns to the previous screen; it must not duplicate entries or silently discard a changed form. The browser board displays screens side by side and scrolls between them only to make design review convenient.

## 3. Visual system

### Color tokens

| Role | Light | Dark |
| --- | --- | --- |
| Board ground / surrounding background | `#E5EDEF` | `#101C21` |
| Main surface | `#FFFFFF` | `#1A2B32` |
| Secondary surface | `#F2F6F7` | `#15232A` |
| Primary text | `#172E35` | `#EEF5F6` |
| Secondary text | `#52666E` | `#B0C3CB` |
| Divider | `#D4DFE2` | `#3C535C` |
| Action accent | `#14645D` | `#8FD6C5` |
| Text on action accent | `#FFFFFF` | `#12362F` |
| Tinted summary / selected surface | `#E3F1ED` | `#233E3C` |
| Destructive text and outline | `#AC303B` | `#FFB3BB` |

Teal communicates interaction and selection. Destructive styling is reserved for deletion and explicit data-loss warnings. Category identity has a name and icon; it never depends on color alone. The board ground is a presentation token, not a requirement that every app screen use the board's outer background.

### Typography and layout

- **Manrope:** headings and monetary amounts; use tabular numerals for aligned amounts where supported.
- **Source Sans 3:** labels, notes, descriptions, and utility text.
- Use native/system sans-serif fallbacks; production font packaging must not require a network connection.
- Use a 4/8-unit spacing rhythm, approximately 24-unit screen gutters, and a single-column phone layout.
- Summary cards use approximately 20-unit corners; buttons and fields approximately 12–15 units.
- Body copy is normally 16 units or greater. Small metadata may be smaller but must support system text scaling and remain readable.
- Currency is explicitly labeled **PKR**. Format amounts with grouping separators and up to two fractional digits. Do not imply a bank balance or available funds.
- Use consistent outline vector icons. No emoji-based navigation or category icons.
- Respect native top/bottom safe areas and the on-screen keyboard. Content scrolls without passing underneath fixed actions or tab bars.

## 4. Core screens

### Overview

Show the current date, **Your spending**, and a Settings control. The summary card contains **Spent today**, the total, the number of expenses recorded, and **This month** with its total.

Below the summary, show today's entries with category icon, note or category-name fallback, category label, and amount. Each entry opens its details. A labeled History shortcut opens the history tab.

Keep **Add expense** prominent near the bottom. Show a concise device-only storage reminder. Do not put a chart between the user and expense entry.

### Add expense

Prioritize the amount field with a visible PKR label and decimal-capable numeric keyboard. Then show category selection, date, and an optional note. Built-in categories are Food & drinks, Transport, Shopping, Bills, Health, and Other.

Use today's date by default. After successful persistence, update totals and history and return to the originating screen with success feedback. Prevent repeat taps from creating duplicate saves. A failed save retains the entire form and provides an explicit retry action; do not show success before persistence succeeds.

### History

Show labeled **Day / Week / Month** controls, previous/next-period buttons, a readable period label, the selected period's spending total and expense count, and entries grouped by date. Each date group displays a subtotal. Each row opens expense details.

A category filter includes **All categories** and active or archived categories. The total, count, and list must all reflect the same date range and filter. Make an active filter visible and provide a way to clear it. Switching range types resets to the current period of the newly selected type.

Keep **Add expense** available. An action originating from a selected day uses that day as the form's default date. Do not carry an old period's date into an unrelated new entry.

## 5. Category management

### Categories

List active categories with an icon, name, and recorded expense count. A row opens the category editor. Include **Add category**.

Show archived categories separately when any exist. Restoring makes a category available for new entries again.

### Add/edit category

Provide a labeled category-name field, a small labeled icon picker, and a live preview. Validate the name beside the field. Adding and editing share the same form, but the title and save action reflect the current operation.

Renaming changes the displayed category label on existing expenses without changing their dates or amounts. The editor explains this before saving.

Archiving requires confirmation. Explain that it hides the category from new entries but preserves existing expenses. Do not offer category deletion that silently removes or reassigns spending history.

**Other** is the protected fallback category: keep it active and retain its name. The native editor should explain this constraint and disable name editing for Other rather than letting a person discover the restriction only on submit. Its icon may be changed.

Category choices for new entries exclude archived categories. An existing expense may retain its archived category when edited; the selected archived option is labeled accordingly.

## 6. Expense details and editing

### Expense details

Show category icon, amount, category name, expense date, optional note, and the device-only storage label. If the note is empty, show **No note added**.

Offer distinct **Edit expense** and **Delete expense** actions.

### Edit expense

Prefill the amount, category, date, and note from the selected record. Saving changes updates that record instead of creating another entry. Recalculate affected daily, weekly, and monthly totals and category counts.

A changed form asks **Discard expense changes?** on cancel/back. **Keep editing** retains the draft; **Discard changes** preserves the saved entry and returns to details.

### Delete confirmation

Name the selected expense using its note/category, amount, and date. State that deletion removes it from History and updates totals, and that deletion cannot be undone.

Use **Keep expense** as the safe action and **Delete expense** as the explicitly destructive action. No data changes until confirmation and successful persistence. After deletion, return to the originating list with updated totals and success feedback. The prototype's deleted-details state is a review aid, not a requirement to strand the user on an empty detail page.

## 7. Settings and first-use experience

### Settings

Include:

- Appearance: **Use device setting**, **Light**, and **Dark**.
- Currency: read-only **PKR · Pakistani rupee**.
- A clear explanation of local storage, no account, and no cloud synchronization.
- A prominent **No recovery in version 1** warning: losing the phone, uninstalling the app, or clearing app data may permanently remove expense history.
- An explicit statement that backup and restore are not available.
- App name and actual installed version. The prototype's version string is illustrative.

Do not show sign-in, bank connection, backup, restore, or cloud controls. Appearance is a local preference and should not affect stored spending data.

### First use / no expenses

Enter the app directly without registration or a mandatory onboarding carousel. Show a zero total, **No expenses yet**, a brief explanation of amount/category entry, and **Add your first expense**.

Show the device-only and no-recovery notice here, not only in Settings. Avoid implying that privacy means recoverability or that device-local storage is an independent backup.

### Empty period or filtered result

Distinguish these states:

- No expenses ever recorded: invite the first entry.
- No expenses today but earlier history exists: say that today's list is empty and earlier entries remain in History.
- No expenses in the selected period: offer another date, **Go to today**, or an entry for that day.
- No matches for a filter: offer clearing the filter or changing the period.

Empty results use zero totals, not missing or stale values.

## 8. Proposed implementation defaults

These explicit defaults were used in the design study. They are UI rules, not database or technology choices:

- Amounts: PKR 0.01–999,999,999, with at most two decimal places.
- Expense dates: today or an earlier date; no future-dated expenses in V1.
- Optional notes: up to 80 characters.
- Category names: trim leading/trailing whitespace; 1–30 characters; case-insensitive uniqueness across active and archived categories.
- Weeks: Monday through Sunday.
- The application uses the device's current local calendar date. The prototype's fixed 3 November 2026 date is sample data only.
- Store and aggregate money exactly using integer minor units or an equivalent decimal representation; do not copy the prototype's floating-point demo arithmetic into production.

Before implementation, encode these defaults in acceptance tests and retain the option to revise them during the written-spec review.

## 9. Feedback, accessibility, and reliability

- Use visible labels and nearby actionable errors. Retain valid input after an error. Focus the first invalid field; use a linked error summary if several fields fail together.
- Account for device-storage read/write failure. Do not render a load error as an empty history, silently reset data, or claim a save succeeded when it failed. Show a clear error and retry action.
- Give save operations immediate pressed/loading feedback and prevent duplicate submissions. Maintain layout bounds when controls change state.
- Use at least 44-point iOS and 48-dp Android touch targets. Small glyphs still receive full hit areas.
- Label icon-only actions; expose selected/pressed states. Hide decorative icons from screen readers.
- Respect reduced motion, large system text, keyboard focus, screen-reader order, and native back behavior.
- Modal confirmations trap focus, initially emphasize the safe action, support cancellation, and return focus to a sensible surviving control when closed.
- Confirm discarding unsaved changes for both add and edit forms. The extended prototype demonstrates this for category editing and expense editing; add-entry discard protection remains a native implementation requirement.
- Test light and dark themes independently. Primary and secondary normal text must meet 4.5:1 contrast; meaningful control indicators must meet applicable non-text contrast requirements.
- Do not rely on swipes, hover, color, or icons alone to expose core operations.

## 10. Design artifacts and verification evidence

The interactive screen board contains twelve screen/state frames:

1. Overview
2. Add expense
3. History
4. Categories
5. Add/edit category
6. Expense details
7. Edit expense
8. Settings
9. First use
10. Empty history
11. Delete confirmation
12. Form feedback

Local artifacts:

- `.superpowers/brainstorm/860-1793715387/content/expense-screens-complete.html` — standalone browser-companion screen board.
- `.superpowers/brainstorm/860-1793715387/everyday-expenses.html` — publishable HTML fragment of the same design.
- `.superpowers/brainstorm/860-1793715387/screens-light.png` — complete light-theme board capture.
- `.superpowers/brainstorm/860-1793715387/screen-dark-mobile.png` — dark-theme category-editor capture.
- `.superpowers/brainstorm/860-1793715387/verify-prototype.cjs` — browser verification script.

Verified using headless Microsoft Edge on 2026-11-03:

- All twelve screen/state frames render; element IDs are unique; both inline script blocks parse.
- Category creation, renaming, archiving, and restoration update the relevant choices while preserving expenses.
- Expense edits update the existing record and totals.
- Delete cancellation preserves the record; confirmed deletion removes it and updates totals.
- Invalid amounts and duplicate category names display validation feedback.
- Category-filtered totals match the filtered records.
- No page-level horizontal overflow at 375×812 and 812×375.
- No browser JavaScript exceptions during the tested flows.
- Full light-theme and dark mobile-editor screenshots were visually reviewed.
- Previously measured core text/button pairs exceed 4.5:1 in both themes.

Limitations: this is not a production persistence test, a full native-device accessibility audit, a complete large-text test, a keyboard-open layout test, or an exhaustive non-text contrast audit. The board expands vertically for review; the native app must use bounded viewports, scrolling content, and safe-area-aware actions. Demo changes reset on reload. Artifact publishing was attempted but unavailable under the session's authentication; the local companion is the available browser preview.

## 11. Next gate

Review this written specification and its explicit implementation defaults before implementation planning. Choose the Android/iPhone technology stack separately; no stack was approved as part of the screen-design review.
