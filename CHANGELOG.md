# Changelog

All notable changes to BudgetKo. Versions are Android versionNames, taken from
`pubspec.yaml`.

## 2.2.0

Backup and restore, a floating navigation bar, and a batch of layout and data
correctness fixes.

### New

**Backup and restore**
Export your whole database to a versioned JSON file and import it again, from
Settings. Restore checks the file before touching anything and does the wipe
and reinsert as a single transaction, so a corrupt or truncated file cannot
leave you with a half-empty database. Row ids are preserved, so transactions
stay linked to their categories and wallets across a round trip.

**Floating navigation bar**
The side drawer is gone. Navigation is now a translucent pill that floats above
your content, with the Quick Add button docked through a gap in the middle.
Reports, Wallets, Goals, Categories, Recurring, Notifications and Settings
moved into a More sheet, which keeps the bar to four targets instead of nine.

**E-Wallet type, with presets**
The GCash wallet type became E-Wallet, so the type describes what it is rather
than naming one provider. Adding a wallet now offers presets: GCash, PayMaya
and Maya under E-Wallet, and BDO, BPI, GoTyme Bank and MariBank under Bank.
Each preset carries its brand colour, and the name stays editable.

**Notes as a prompt on save**
Quick Add no longer has a note field in the middle of the screen. Tap Save and
BudgetKo asks whether you want to add a note, then shows a multiline field only
if you say yes.

**Goal creation previews itself**
The create-goal sheet opens with a live preview card that updates as you type,
so the colour and photo you pick are visible before you commit. The image is
now the card background, with a camera button to swap it and a Remove pill to
clear it.

**Hardware back goes where you came from**
AppShell keeps a history stack behind the back gesture, so backing out of Quick
Add returns you to whichever screen opened it rather than always dropping you
on the dashboard.

### Improved

**Savings goal cards are lighter**
Three buttons in the card header became two: add stays, and subtract, change
photo and delete moved into a More sheet, which stops the destructive action
from competing with the primary one for space. The per-card glow is replaced by
a 1px border, the photo is a compact banner at the top instead of a block in
the middle that also rendered when there was no image, and three overlapping
number lines collapsed to two. Deadlines turn amber inside a week and red once
past.

**Budget figures are readable**
Category budget rows built the value as one muted grey string, so the amount
spent and the limit had no visual relationship. The spent figure is now bold,
takes the row's colour, and turns red when you are over budget, agreeing with
the progress bar and the status pill. Gaps are uniform so rows line up whether
or not a badge is showing.

**Dashboard goal amounts sit in the corner**
The amount was vertically centred beside the goal name. It now anchors to the
top right, with the same spent and limit weight split as the budget rows.

**The splash screen earned its time**
The old one held a spinner for two seconds while nothing loaded, since
onboarding state is read before the first frame. It now runs about 1.55s as a
branded animation: a radial wash, a faint chart motif, drifting glow orbs, and
a staggered entrance for the logo, name and tagline.

**The number pad fills the screen**
Keys were locked to a fixed 58px, which left a gap on taller screens. The rows
are now flexible and share the available space with the category and wallet
selectors, so the pad grows to fit.

### Fixed

**The note field could not be typed into**
Tapping the note field raised the keyboard, which changed the layout, which
rebuilt the field and destroyed it along with its focus, closing the keyboard
again. The field now keeps a stable position in the widget tree. Removing the
field entirely in favour of the save prompt closes this off for good.

**The screen overflowed at the bottom while typing**
The keyboard shrank the window while the fixed sections above it kept their
height, and the column overflowed. Fixed alongside the note prompt.

**The save button jumped every time the keyboard opened**
The Scaffold resizes its body for the keyboard by default, and the bottom safe
area inset drops to zero the moment one appears, so the pinned save bar rode up
and down on each keystroke. The Scaffold no longer resizes, and the bottom
inset now comes from `viewPadding`, which does not change when a keyboard opens.

**Category budgets could show stale data**
The provider did a single read and never subscribed, so adding or renaming a
category left the budget screen showing its old status. It now watches the
category stream.

**Deleting by swipe could race the totals**
The row removal was not awaited before the aggregates were recalculated, so
the refresh could run against data that had not been deleted yet.

**A goal with a zero target could crash**
Progress divided by the target, which produced NaN and took `round()` with it.
The shared `goalProgress` helper now returns 0 for a zero target, and both the
goals screen and the dashboard use it.

**The in-app version was wrong**
Settings showed a hardcoded `2.1.0` that had already drifted from `pubspec`, so
bumping the declared version changed what Android reported in App info but left
the row inside the app stale. It now reads the real value from the package, so
the two cannot disagree again.
