import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

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

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

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