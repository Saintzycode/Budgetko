<div align="center">
  <img src="assets/android/Logo.png" alt="BudgetKo logo" width="140" />

  # BudgetKo

  **Know where your money went, before the month ends.**

  A personal finance app for Android that keeps wallets, spending, budgets
  and savings goals in one place, entirely on your device.
</div>

---

## Why it exists

Most budgeting apps want an account, a sync service and a subscription before
they will tell you what you spent. BudgetKo does the opposite. It opens straight
to your data, works with no network, and stores everything in a local database
you can export to a file at any time.

It is built around one habit: recording a transaction should take seconds, not
a form. The Quick Add flow is a calculator with a docked number pad, the amount
always visible, and the note is an optional prompt on the way out rather than
another field you have to scroll past.

## What it does

**Wallets**
Track cash, e-wallets and bank accounts separately, each with its own balance.
Adding a wallet offers presets for GCash, PayMaya, BDO, BPI, GoTyme Bank and
MariBank, and you can name anything else yourself.

**Quick add**
A number pad, a category and a wallet, and you are done. Optional notes are
offered as a yes or no prompt when you save. Hardware back returns you to
whichever screen you opened it from.

**Budgets**
Set a monthly limit per category. Each row shows what is spent against what is
left, turns amber as you approach the limit and red once you are over. Optional
rollover carries unused budget into the next month without needing a database
migration, since the effective limit is computed rather than stored.

**Savings goals**
Set a target and a deadline, add a photo to make it real, and contribute in
either direction. The create sheet previews the card live as you type, and
deadlines turn amber inside a week and red once passed.

**Spending insights**
Trends, day-of-week patterns and category breakdowns, so the question becomes
*when* and *what* rather than just *how much*.

**Recurring transactions**
Salary, bills and subscriptions log themselves, with a validator that rejects
amounts of zero or less.

**Notifications**
Local alerts for large transactions and for crossing a budget limit, with an
in-app inbox so nothing is missed if notifications are dismissed.

**Backup and restore**
Export the whole database to a versioned JSON file and import it again. Restore
validates the file before touching anything and does the wipe and reinsert in
one transaction, so a corrupt file cannot leave you with a half-empty database.
Row ids are preserved, so the links between transactions, categories and
wallets survive the round trip.

## Design notes

A few decisions that are not obvious from the code:

- **Local first, no account.** There is no sync and no telemetry. Your data
  never leaves the device unless you export it.
- **Restore is transactional.** A failed import rolls back rather than
  leaving a partial database.
- **Rollover is computed, not stored.** Changing the rollover setting
  reinterprets existing data instead of migrating it.
- **The keyboard never moves the save button.** The Scaffold does not resize
  for the keyboard, and the bottom inset comes from `viewPadding`, which does
  not change when a keyboard opens.
- **Goal progress is a shared helper.** `goalProgress` guards against a zero
  target so it returns `0` rather than `NaN`.

## Tech stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter 3 / Dart 3 |
| State management | Riverpod |
| Navigation | GoRouter with a shell route and history stack |
| Database | Drift over SQLite, schema version 3 |
| Charts | FL Chart |
| Notifications | flutter_local_notifications with timezone handling |
| Backup | Custom versioned JSON, native file picker over a platform channel |
| Fonts | Google Fonts |

## Project structure

```text
lib/
  core/
    backup/         JSON backup and restore
    budget/         Budget status and rollover computation
    insights/       Spending insights
    notifications/  Local notification triggers
    router.dart     Routes, navigation shell, floating nav bar
    theme/          Colours, text styles, shared widgets
    utils/          Formatters, icon maps, shared helpers
  data/
    database/       Drift tables, DAOs, schema
    repositories/   Riverpod providers
  features/
    alerts/         Budget limits
    categories/     Category management
    dashboard/      Home overview
    goals/          Savings goals
    notifications/  In-app inbox
    onboarding/     First run
    recurring/      Recurring transactions
    reports/        Charts and breakdowns
    settings/       Preferences, backup, danger zone
    splash/         Branded splash
    transactions/   List, quick add, edit sheet
    wallets/        Wallet management
```

## Getting started

### Prerequisites

- Flutter 3.x with Dart 3
- Android SDK, and a device or emulator

### Install and run

```bash
git clone https://github.com/Saintzycode/Budgetko.git
cd Budgetko
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Drift generates its code from the table definitions, so `build_runner` has to
run at least once before the app will compile.

### Common commands

```bash
flutter analyze
flutter test
flutter build apk --release
```

## Notes for contributors

- `flutter analyze` is expected to be clean before opening a pull request.
- Schema changes need a migration and a `schemaVersion` bump in
  `lib/data/database/app_database.dart`.
- Prefer extending the shared icon maps in `lib/core/utils/category_icons.dart`
  over adding another private lookup table.
- Screenshot and backup formats are versioned. Do not change them without
  bumping the version and keeping the old reader working.

## License

This project is currently unlicensed. Add a license file before distributing
it.
