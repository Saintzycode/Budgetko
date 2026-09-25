# BudgetKo — Google Play listing

Copy for the Play Console. Limits are Google Play's, not arbitrary: the app
name caps at 30 characters, the short description at 80, and the full
description at 4000.

## App name

```
BudgetKo
```

8 of 30 characters.

## Short description

```
Offline budget and savings tracker for wallets, spending limits and goals.
```

70 of 80 characters.

## Full description

```
BudgetKo shows you where your money actually went, before the month ends.

Most budgeting apps want an account, a sync service and a subscription
before they will answer that question. BudgetKo does the opposite. It opens
straight to your data, works with no network, and keeps everything on your
phone. Nothing is uploaded, and there is no account to create.

Recording a transaction should take seconds, not a form. The Quick Add flow
is a calculator with a docked number pad, the amount always in view, and the
note is an optional prompt on the way out instead of another field to scroll
past.

WALLETS
Track cash, e-wallets and bank accounts separately, each with its own
balance. Adding one offers presets for GCash, PayMaya, Maya, BDO, BPI,
GoTyme Bank and MariBank, and you can name anything else yourself.

BUDGETS
Set a monthly limit per category. Each row shows what is spent against what
is left, turns amber as you approach the limit and red once you are over.
Optional rollover carries unused budget into the next month.

SAVINGS GOALS
Set a target and a deadline, add a photo to make it real, and contribute in
either direction. The create screen previews the card live as you type.
Deadlines turn amber inside a week and red once passed.

INSIGHTS
Trends, day-of-week patterns and category breakdowns, so the question
becomes when and what, not just how much.

RECURRING
Salary, bills and subscriptions log themselves.

ALERTS
Local notifications for large transactions and for crossing a limit, with an
in-app inbox so nothing is missed.

BACKUP
Export everything to a file and import it again. Restore validates before it
touches anything and runs as a single transaction, so a corrupt file cannot
leave you with a half-empty database. Your data is yours to take with you.

PRIVACY
No account. No ads. No analytics. No network calls. Your financial data never
leaves your device unless you choose to export it.

Free and open source.
```

## What's new in 2.2.0

```
Floating navigation
The drawer is gone. Navigation is now a translucent bar that floats above
your content, with a Quick Add button docked in the middle.

Notes moved to save
Adding a transaction no longer has a note field in the way. When you tap
Save, BudgetKo asks if you want to add a note, and leaves it to you.

Goal creation previews itself
The savings goal screen now shows the card as you build it, so the colour
and photo you choose are visible before you save.

E-wallets and more banks
GCash became E-Wallet, and you can now pick from PayMaya, Maya, BDO, BPI,
GoTyme Bank and MariBank as presets.

Backup and restore
Export your data to a file and import it again, from Settings.

Faster splash
The launch screen no longer sits on a spinner for two seconds while nothing
loads.
```

## Keywords

Use these in the Play listing search terms rather than the description, where
they read as spam:

```
budget, budgeting, expense tracker, personal finance, savings goals, money,
spending, wallet, budget app, gcash, paymaya, bdo, bpi, offline, no account
```

## Before you upload

- The current build is **signed with the debug key**. Play requires a real
  upload keystore, and switching keys means users must uninstall first.
- The launcher name currently renders as lowercase `budgetko`. Set
  `android:label` in `AndroidManifest.xml` to `BudgetKo`.
- `applicationId` is still `com.example.budgetko`. This cannot be changed
  after the first upload, so decide the final id now.
- `android:allowBackup` is not disabled. If you want to opt out of Google's
  automatic cloud backup of app data, set it to `false` in the manifest.
