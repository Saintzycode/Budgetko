/// Progression maths for savings goals.
///
/// Everything here is a pure function over the contribution ledger so it
/// can be unit tested and recomputed cheaply whenever a row changes.
library;

/// One milestone on the way to funding a goal.
class Milestone {
  /// Progress fraction this milestone sits at.
  final double at;

  final String label;
  final String title;

  const Milestone(this.at, this.label, this.title);

  static const all = <Milestone>[
    Milestone(0.25, '25%', 'Getting there'),
    Milestone(0.50, '50%', 'Halfway'),
    Milestone(0.75, '75%', 'Almost there'),
    Milestone(1.00, '100%', 'Fully funded'),
  ];

  /// The first milestone not yet reached, or null when complete.
  static Milestone? nextReached(double progress) {
    for (final m in all) {
      if (progress < m.at) return m;
    }
    return null;
  }

  bool isReached(double progress) => progress >= at;
}

/// A dated contribution, as stored in the ledger.
class Contribution {
  final int goalId;
  final double amount;
  final DateTime at;

  const Contribution({
    required this.goalId,
    required this.amount,
    required this.at,
  });
}

/// Aggregate progression across every goal.
class SavingsStats {
  /// Money currently sitting in goals.
  final double totalSaved;

  /// Money deposited, ignoring later withdrawals. This is what XP is
  /// earned on, so taking money back out does not remove progress you
  /// already made; it just stops counting towards it.
  final double totalDeposited;

  /// Consecutive weeks, ending this week or last, with at least one
  /// deposit.
  final int weekStreak;

  final int bestWeekStreak;

  /// This calendar month's deposits.
  final double savedThisMonth;

  /// Deposits made in the last 30 days.
  final double savedLast30Days;

  const SavingsStats({
    required this.totalSaved,
    required this.totalDeposited,
    required this.weekStreak,
    required this.bestWeekStreak,
    required this.savedThisMonth,
    required this.savedLast30Days,
  });

  static const empty = SavingsStats(
    totalSaved: 0,
    totalDeposited: 0,
    weekStreak: 0,
    bestWeekStreak: 0,
    savedThisMonth: 0,
    savedLast30Days: 0,
  );
}

/// Peso needed per point of XP. Every hundred pesos deposited is one XP.
const double kXpPerPeso = 100;

/// Highest level the ladder will count to. Cumulative XP grows with the
/// square of the level, so this only guards against a corrupt total
/// looping forever.
const int kMaxLevel = 60;

/// XP earned on everything ever deposited.
///
/// Deliberately not one per peso: at that rate a square root curve put
/// level 10 within reach of saving eighty pesos, which made the whole
/// ladder meaningless. One XP per hundred pesos puts Master at roughly
/// forty five thousand saved, which takes real commitment.
int savingsXp(double totalDeposited) {
  if (totalDeposited <= 0) return 0;
  return (totalDeposited / kXpPerPeso).floor();
}

/// Total XP required to have reached [level].
///
/// Cumulative XP for level n is 5n(n-1), giving 0, 10, 30, 60, 100,
/// 150... so each level costs 10 more XP than the last: ten pesos a
/// hundred to reach Starter, rising to a hundred pesos a hundred to push
/// past Master.
int savingsXpForLevel(int level) {
  final n = level <= 1 ? 1 : level;
  return 5 * n * (n - 1);
}

/// XP still needed to get from [level] to the next one.
int savingsXpForNextLevel(int level) =>
    10 * (level <= 1 ? 1 : level);

/// Level for a given XP total.
int savingsLevel(int xp) {
  if (xp <= 0) return 1;
  var level = 1;
  while (level < kMaxLevel &&
      xp >= savingsXpForLevel(level + 1)) {
    level++;
  }
  return level;
}

/// XP already earned towards the next level, for drawing the progress bar.
int savingsXpAtLevelStart(int level) => savingsXpForLevel(level);

/// Progress through the current level, 0 to 1.
double savingsLevelProgress(int xp) {
  final level = savingsLevel(xp);
  final start = savingsXpAtLevelStart(level);
  final needed = savingsXpForNextLevel(level);
  if (needed <= 0) return 1;
  return ((xp - start) / needed).clamp(0.0, 1.0);
}

/// Title shown against a level. Master now needs roughly forty five
/// thousand pesos deposited to reach.
String savingsLevelTitle(int level) {
  if (level >= 10) return 'Master';
  if (level >= 8) return 'Champion';
  if (level >= 6) return 'Builder';
  if (level >= 4) return 'Saver';
  if (level >= 2) return 'Starter';
  return 'Beginner';
}

/// Monday-based week key, used to group deposits into weeks.
DateTime _weekStart(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Builds the aggregate stats from a ledger and the live goal totals.
SavingsStats buildSavingsStats({
  required List<Contribution> contributions,
  required double totalSaved,
  DateTime? now,
}) {
  if (contributions.isEmpty) {
    return SavingsStats(
      totalSaved: totalSaved,
      totalDeposited: 0,
      weekStreak: 0,
      bestWeekStreak: 0,
      savedThisMonth: 0,
      savedLast30Days: 0,
    );
  }

  final today = now ?? DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);

  var deposited = 0.0;
  var thisMonth = 0.0;
  var last30 = 0.0;
  final weeks = <DateTime>{};

  for (final c in contributions) {
    if (c.amount <= 0) continue;
    deposited += c.amount;
    weeks.add(_weekStart(c.at));
    if (c.at.year == today.year && c.at.month == today.month) {
      thisMonth += c.amount;
    }
    if (!c.at.isAfter(
      startOfToday.subtract(const Duration(days: 29)),
    )) {
      last30 += c.amount;
    }
  }

  // Walk backwards from the current week. A gap anywhere ends the
  // streak, so depositing last week and this week counts as two.
  final sorted = weeks.toList()
    ..sort((a, b) => b.compareTo(a));
  var current = _weekStart(today);

  var streak = 0;
  // Allow the streak to still be alive if this week has no deposit yet
  // but last week did, otherwise opening the app on a Monday would zero it.
  if (!weeks.contains(current)) {
    current = current.subtract(const Duration(days: 7));
  }
  var cursor = current;
  while (weeks.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }

  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final week in sorted) {
    if (previous != null &&
        previous.difference(week).inDays == 7) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    previous = week;
  }

  return SavingsStats(
    totalSaved: totalSaved,
    totalDeposited: deposited,
    weekStreak: streak,
    bestWeekStreak: best > streak ? best : streak,
    savedThisMonth: thisMonth,
    savedLast30Days: last30,
  );
}
