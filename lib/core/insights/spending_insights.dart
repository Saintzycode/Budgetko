class CategoryChange {
  final int categoryId;
  final String name;
  final double current;
  final double previous;
  final double delta;
  final bool hasPrevious;

  const CategoryChange({
    required this.categoryId,
    required this.name,
    required this.current,
    required this.previous,
    required this.delta,
    required this.hasPrevious,
  });
}

class SpendingInsights {
  final double currentExpense;
  final double previousExpense;
  final bool hasPreviousMonth;

  /// Null when there is no previous month to compare against.
  final double? monthOverMonthPercent;

  final double weekendSpend;
  final double weekdaySpend;
  final int weekendDays;
  final int weekdayDays;

  /// Average spend per weekend day vs per weekday day, as a percentage
  /// premium. Null when there is not enough data to compare.
  final double? weekendPremiumPercent;

  final int? topSpendWeekday;
  final List<CategoryChange> topIncreases;
  final bool isEmpty;

  const SpendingInsights({
    required this.currentExpense,
    required this.previousExpense,
    required this.hasPreviousMonth,
    required this.monthOverMonthPercent,
    required this.weekendSpend,
    required this.weekdaySpend,
    required this.weekendDays,
    required this.weekdayDays,
    required this.weekendPremiumPercent,
    required this.topSpendWeekday,
    required this.topIncreases,
    required this.isEmpty,
  });

  const SpendingInsights.empty()
      : currentExpense = 0,
        previousExpense = 0,
        hasPreviousMonth = false,
        monthOverMonthPercent = null,
        weekendSpend = 0,
        weekdaySpend = 0,
        weekendDays = 0,
        weekdayDays = 0,
        weekendPremiumPercent = null,
        topSpendWeekday = null,
        topIncreases = const [],
        isEmpty = true;
}

SpendingInsights buildSpendingInsights({
  required double currentExpense,
  required double previousExpense,
  required Map<int, double> currentByCategory,
  required Map<int, double> previousByCategory,
  required Map<int, double> byWeekday,
  required Map<int, String> categoryNames,
}) {
  final hasPrevious = previousExpense > 0;

  double? momPercent;
  if (hasPrevious) {
    momPercent =
        ((currentExpense - previousExpense) / previousExpense) * 100;
  }

  var weekendSpend = 0.0;
  var weekdaySpend = 0.0;
  var weekendDays = 0;
  var weekdayDays = 0;
  byWeekday.forEach((weekday, amount) {
    if (weekday == DateTime.saturday ||
        weekday == DateTime.sunday) {
      weekendSpend += amount;
      weekendDays++;
    } else {
      weekdaySpend += amount;
      weekdayDays++;
    }
  });

  double? weekendPremium;
  if (weekendDays > 0 && weekdayDays > 0 && weekdaySpend > 0) {
    final weekendAvg = weekendSpend / weekendDays;
    final weekdayAvg = weekdaySpend / weekdayDays;
    weekendPremium = ((weekendAvg - weekdayAvg) / weekdayAvg) * 100;
  }

  int? topWeekday;
  if (byWeekday.isNotEmpty) {
    final sorted = byWeekday.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.first.value > 0) {
      topWeekday = sorted.first.key;
    }
  }

  final changes = <CategoryChange>[];
  for (final entry in currentByCategory.entries) {
    final previous = previousByCategory[entry.key] ?? 0;
    final delta = entry.value - previous;
    if (delta > 0) {
      changes.add(CategoryChange(
        categoryId: entry.key,
        name: categoryNames[entry.key] ?? 'Category',
        current: entry.value,
        previous: previous,
        delta: delta,
        hasPrevious: previous > 0,
      ));
    }
  }
  changes.sort((a, b) => b.delta.compareTo(a.delta));

  return SpendingInsights(
    currentExpense: currentExpense,
    previousExpense: previousExpense,
    hasPreviousMonth: hasPrevious,
    monthOverMonthPercent: momPercent,
    weekendSpend: weekendSpend,
    weekdaySpend: weekdaySpend,
    weekendDays: weekendDays,
    weekdayDays: weekdayDays,
    weekendPremiumPercent: weekendPremium,
    topSpendWeekday: topWeekday,
    topIncreases: changes.take(3).toList(),
    isEmpty: currentExpense == 0 && previousExpense == 0,
  );
}
