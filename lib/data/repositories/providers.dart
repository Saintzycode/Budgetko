import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../database/app_database.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/notification_triggers.dart';
import '../../core/insights/spending_insights.dart';
import '../../core/budget/budget_status.dart';

// ── Database singleton ─────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ───────────────────────────────────────────────────────────────────────

final walletsDaoProvider = Provider<WalletsDao>((ref) {
  return ref.watch(databaseProvider).walletsDao;
});

final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  return ref.watch(databaseProvider).transactionsDao;
});

final savingsGoalsDaoProvider = Provider<SavingsGoalsDao>((ref) {
  return ref.watch(databaseProvider).savingsGoalsDao;
});

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return ref.watch(databaseProvider).categoriesDao;
});

final recurringDaoProvider = Provider<RecurringDao>((ref) {
  return ref.watch(databaseProvider).recurringDao;
});

// ── Selected month ─────────────────────────────────────────────────────────────

final selectedMonthProvider =
    StateNotifierProvider<SelectedMonthNotifier, DateTime>((ref) {
  return SelectedMonthNotifier();
});

class SelectedMonthNotifier extends StateNotifier<DateTime> {
  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;
  bool _followsCurrentMonth = true;

  SelectedMonthNotifier() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncCurrentMonth();
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: _syncCurrentMonth,
    );
  }

  void setMonth(DateTime month) {
    final current = _currentMonth();
    final same = _isSameMonth(month, current);
    _followsCurrentMonth = same;
    state = same ? current : DateTime(month.year, month.month);
  }

  void useCurrentMonth() {
    _followsCurrentMonth = true;
    state = DateTime.now();
  }

  void _syncCurrentMonth() {
    if (!_followsCurrentMonth) return;
    final now = DateTime.now();
    final stateDay = DateTime(state.year, state.month, state.day);
    final today = DateTime(now.year, now.month, now.day);
    if (stateDay != today) {
      state = now;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

// ── Selected wallet ────────────────────────────────────────────────────────────

final selectedWalletProvider = StateProvider<int?>((ref) => null);

// ── Wallet streams ─────────────────────────────────────────────────────────────

final allWalletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletsDaoProvider).watchAllWallets();
});

// ── Transaction streams ────────────────────────────────────────────────────────

final transactionsForMonthProvider =
    StreamProvider<List<TransactionWithDetails>>((ref) {
  final dao = ref.watch(transactionsDaoProvider);
  final month = ref.watch(selectedMonthProvider);
  return dao.watchTransactionsForMonth(month);
});

final allTransactionsProvider =
    StreamProvider<List<TransactionWithDetails>>((ref) {
  return ref.watch(transactionsDaoProvider).watchAllTransactions();
});

final monthlyTotalsProvider = FutureProvider<MonthlyTotals>((ref) {
  final dao = ref.watch(transactionsDaoProvider);
  final month = ref.watch(selectedMonthProvider);
  final walletId = ref.watch(selectedWalletProvider);
  return dao.getMonthlyTotals(month, walletId: walletId);
});

final spendingByCategoryProvider =
    FutureProvider<Map<int, double>>((ref) {
  final dao = ref.watch(transactionsDaoProvider);
  final month = ref.watch(selectedMonthProvider);
  final walletId = ref.watch(selectedWalletProvider);
  return dao.getSpendingByCategory(month, walletId: walletId);
});

final last6MonthsProvider =
    FutureProvider<List<MonthlyTotals>>((ref) {
  return ref
      .watch(transactionsDaoProvider)
      .getLast6MonthsTotals();
});

// ── Goals streams ──────────────────────────────────────────────────────────────

final activeGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(savingsGoalsDaoProvider).watchActiveGoals();
});

final allGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(savingsGoalsDaoProvider).watchAllGoals();
});

// ── Categories streams ─────────────────────────────────────────────────────────

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesDaoProvider).watchAllCategories();
});

// ── Recurring streams ──────────────────────────────────────────────────────────

final allRecurringProvider =
    StreamProvider<List<RecurringWithDetails>>((ref) {
  return ref.watch(recurringDaoProvider).watchAllRecurring();
});

// ── Transaction Search & Filter ────────────────────────────────────────────────

final transactionSearchProvider = StateProvider<String>((ref) => '');
final transactionFilterProvider = StateProvider<String>((ref) => 'all');
final transactionCategoryProvider = StateProvider<int?>((ref) => null);

final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionWithDetails>>>((ref) {
  final txnsAsync = ref.watch(transactionsForMonthProvider);
  final search = ref.watch(transactionSearchProvider).toLowerCase();
  final filter = ref.watch(transactionFilterProvider);
  final categoryId = ref.watch(transactionCategoryProvider);

  return txnsAsync.whenData((txns) {
    return txns.where((t) {
      if (categoryId != null &&
          t.transaction.categoryId != categoryId) {
        return false;
      }
      if (filter != 'all' && t.transaction.type != filter) {
        return false;
      }
      if (search.isNotEmpty) {
        final note = (t.transaction.note ?? '').toLowerCase();
        final cat = (t.category?.name ?? '').toLowerCase();
        if (!note.contains(search) && !cat.contains(search)) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

// ── Budget provider ────────────────────────────────────────────────────────────

final monthlyBudgetProvider =
    StateNotifierProvider<MonthlyBudgetNotifier, double>((ref) {
  return MonthlyBudgetNotifier();
});

class MonthlyBudgetNotifier extends StateNotifier<double> {
  MonthlyBudgetNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('monthly_budget') ?? 0;
  }

  Future<void> setBudget(double budget) async {
    state = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', budget);
  }
}

// ── Monthly income provider ────────────────────────────────────────────────────

final monthlyIncomeProvider =
    StateNotifierProvider<MonthlyIncomeNotifier, double>((ref) {
  return MonthlyIncomeNotifier();
});

class MonthlyIncomeNotifier extends StateNotifier<double> {
  MonthlyIncomeNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('monthly_income') ?? 0;
  }

  Future<void> setIncome(double income) async {
    state = income;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_income', income);
  }
}

// ── Notification settings ────────────────────────────────────────────────────

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettings {
  final bool enabled;
  final bool overspend;
  final bool daily;
  final int dailyHour;
  final int dailyMinute;
  final bool recurring;
  final bool goals;
  final bool quickAdd;

  const NotificationSettings({
    this.enabled = true,
    this.overspend = true,
    this.daily = true,
    this.dailyHour = 20,
    this.dailyMinute = 0,
    this.recurring = true,
    this.goals = true,
    this.quickAdd = true,
  });

  String get dailyLabel {
    final h = dailyHour % 12 == 0 ? 12 : dailyHour % 12;
    final m = dailyMinute.toString().padLeft(2, '0');
    final suffix = dailyHour < 12 ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? overspend,
    bool? daily,
    int? dailyHour,
    int? dailyMinute,
    bool? recurring,
    bool? goals,
    bool? quickAdd,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      overspend: overspend ?? this.overspend,
      daily: daily ?? this.daily,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      recurring: recurring ?? this.recurring,
      goals: goals ?? this.goals,
      quickAdd: quickAdd ?? this.quickAdd,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier()
      : super(const NotificationSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(NotifKeys.master) ?? true,
      overspend:
          prefs.getBool(NotifKeys.overspend) ?? true,
      daily: prefs.getBool(NotifKeys.daily) ?? true,
      dailyHour: prefs.getInt(NotifKeys.dailyHour) ?? 20,
      dailyMinute:
          prefs.getInt(NotifKeys.dailyMinute) ?? 0,
      recurring:
          prefs.getBool(NotifKeys.recurring) ?? true,
      goals: prefs.getBool(NotifKeys.goals) ?? true,
      quickAdd:
          prefs.getBool(NotifKeys.quickAdd) ?? true,
    );
    await _refreshSchedule();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifKeys.master, state.enabled);
    await prefs.setBool(
        NotifKeys.overspend, state.overspend);
    await prefs.setBool(NotifKeys.daily, state.daily);
    await prefs.setInt(
        NotifKeys.dailyHour, state.dailyHour);
    await prefs.setInt(
        NotifKeys.dailyMinute, state.dailyMinute);
    await prefs.setBool(
        NotifKeys.recurring, state.recurring);
    await prefs.setBool(NotifKeys.goals, state.goals);
    await prefs.setBool(
        NotifKeys.quickAdd, state.quickAdd);
    await _refreshSchedule();
  }

  Future<void> _refreshSchedule() async {
    await refreshDailyReminder();
  }

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    await _save();
    if (v) {
      await NotificationService.instance
          .requestPermissions();
    }
  }

  Future<void> setOverspend(bool v) async {
    state = state.copyWith(overspend: v);
    await _save();
  }

  Future<void> setDaily(bool v) async {
    state = state.copyWith(daily: v);
    await _save();
  }

  Future<void> setDailyTime(int hour, int minute) async {
    state = state.copyWith(
        dailyHour: hour, dailyMinute: minute);
    await _save();
  }

  Future<void> setRecurring(bool v) async {
    state = state.copyWith(recurring: v);
    await _save();
  }

  Future<void> setGoals(bool v) async {
    state = state.copyWith(goals: v);
    await _save();
  }

  Future<void> setQuickAdd(bool v) async {
    state = state.copyWith(quickAdd: v);
    await _save();
  }
}

// ── Notification inbox ─────────────────────────────────────────────────────────

final notificationsDaoProvider =
    Provider<NotificationsDao>((ref) {
  return ref.watch(databaseProvider).notificationsDao;
});

final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationsDaoProvider).watchAll();
});

final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) =>
            list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// ── Spending insights ──────────────────────────────────────────────────────────

final spendingInsightsProvider =
    FutureProvider<SpendingInsights>((ref) async {
  final dao = ref.watch(transactionsDaoProvider);
  final month = ref.watch(selectedMonthProvider);
  final walletId = ref.watch(selectedWalletProvider);

  final previousMonth = DateTime(month.year, month.month - 1);
  final currentTotals =
      await dao.getMonthlyTotals(month, walletId: walletId);
  final previousTotals =
      await dao.getMonthlyTotals(previousMonth, walletId: walletId);
  final currentByCategory = await dao.getSpendingByCategory(
      month,
      walletId: walletId);
  final previousByCategory = await dao.getSpendingByCategory(
      previousMonth,
      walletId: walletId);
  final byWeekday = await dao.getSpendingByDayOfWeek(
      month,
      walletId: walletId);
  final categories =
      await ref.watch(categoriesDaoProvider).getAllCategories();

  return buildSpendingInsights(
    currentExpense: currentTotals.expense,
    previousExpense: previousTotals.expense,
    currentByCategory: currentByCategory,
    previousByCategory: previousByCategory,
    byWeekday: byWeekday,
    categoryNames: {for (final c in categories) c.id: c.name},
  );
});

// ── Budget carry-over ───────────────────────────────────────────────────────────

const String kCarryoverEnabledKey = 'budget_carryover_enabled';

final carryoverEnabledProvider =
    StateNotifierProvider<CarryoverNotifier, bool>((ref) {
  return CarryoverNotifier();
});

class CarryoverNotifier extends StateNotifier<bool> {
  CarryoverNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kCarryoverEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kCarryoverEnabledKey, v);
  }
}

final categoryBudgetStatusProvider =
    FutureProvider<List<CategoryBudgetStatus>>((ref) async {
  final carryover = ref.watch(carryoverEnabledProvider);
  final month = ref.watch(selectedMonthProvider);
  final walletId = ref.watch(selectedWalletProvider);
  final dao = ref.watch(transactionsDaoProvider);

  // Watch the category stream so this recomputes whenever a category is
  // added, edited, renamed or deleted. Falls back to a direct read only
  // while the stream has not emitted its first value yet.
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrNull ??
      await ref.watch(categoriesDaoProvider).getAllCategories();
  final spending = await dao.getSpendingByCategory(
      month,
      walletId: walletId);
  final previousMonth = DateTime(month.year, month.month - 1);
  final previousSpending = await dao.getSpendingByCategory(
      previousMonth,
      walletId: walletId);
  final hasPriorData = previousSpending.isNotEmpty;

  final statuses = <CategoryBudgetStatus>[];
  for (final category in categories) {
    if (category.isIncome) continue;
    final baseLimit = category.monthlyLimit ?? 0;
    final spent = spending[category.id] ?? 0;
    final previousSpent = previousSpending[category.id] ?? 0;
    final rolledOver = computeRollover(
      baseLimit: baseLimit,
      previousSpent: previousSpent,
      carryoverEnabled: carryover,
      hasPriorData: hasPriorData,
    );
    statuses.add(CategoryBudgetStatus(
      category: category,
      baseLimit: baseLimit,
      effectiveLimit: baseLimit + rolledOver,
      rolledOver: rolledOver,
      spent: spent,
      previousSpent: previousSpent,
    ));
  }

  statuses.sort((a, b) {
    if (a.baseLimit <= 0 && b.baseLimit <= 0) {
      return a.category.name.compareTo(b.category.name);
    }
    if (a.baseLimit <= 0) return 1;
    if (b.baseLimit <= 0) return -1;
    return b.effectiveLimit.compareTo(a.effectiveLimit);
  });
  return statuses;
});

// ── Onboarding ─────────────────────────────────────────────────────────────────

const String kOnboardingCompleteKey = 'onboarding_complete';

final onboardingComplete = ValueNotifier<bool>(false);

Future<void> loadOnboardingState() async {
  final prefs = await SharedPreferences.getInstance();
  onboardingComplete.value =
      prefs.getBool(kOnboardingCompleteKey) ?? false;
}

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompleteKey, true);
  onboardingComplete.value = true;
}

Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kOnboardingCompleteKey);
  onboardingComplete.value = false;
}

// ── Shared invalidation ─────────────────────────────────────────────────────────

void invalidateTransactionAggregates(WidgetRef ref) {
  ref
    ..invalidate(monthlyTotalsProvider)
    ..invalidate(spendingByCategoryProvider)
    ..invalidate(spendingInsightsProvider)
    ..invalidate(categoryBudgetStatusProvider)
    ..invalidate(last6MonthsProvider)
    ..invalidate(allTransactionsProvider)
    ..invalidate(transactionsForMonthProvider);
}

/// Reads the version from the installed package so the About row always
/// matches what pubspec.yaml declares and what Android reports.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
