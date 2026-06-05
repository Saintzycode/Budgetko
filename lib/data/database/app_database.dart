import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // 'cash' | 'gcash' | 'bank'
  TextColumn get icon => text()();
  TextColumn get color => text()();
  RealColumn get balance => real().withDefault(const Constant(0))();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  RealColumn get monthlyLimit => real().nullable()();
  BoolColumn get isIncome =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().withLength(max: 200).nullable()();
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  TextColumn get type => text()(); // 'income' | 'expense' | 'transfer'
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount =>
      real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get color =>
      text().withDefault(const Constant('#1D9E75'))();
  TextColumn get icon =>
      text().withDefault(const Constant('savings'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().withLength(max: 200).nullable()();
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  TextColumn get type => text()();
  TextColumn get frequency => text()(); // 'daily'|'weekly'|'monthly'
  IntColumn get dayOfWeek => integer().nullable()();
  IntColumn get dayOfMonth => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get lastRunAt => dateTime().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─── Result classes ────────────────────────────────────────────────────────────

class TransactionWithDetails {
  final Transaction transaction;
  final Category? category;
  final Wallet? wallet;
  const TransactionWithDetails({
    required this.transaction,
    this.category,
    this.wallet,
  });
}

class MonthlyTotals {
  final double income;
  final double expense;
  const MonthlyTotals({required this.income, required this.expense});
  double get savings => income - expense;
  double get savingsRate =>
      income > 0 ? (savings / income) * 100 : 0;
}

class RecurringWithDetails {
  final RecurringTransaction recurring;
  final Category? category;
  final Wallet? wallet;
  const RecurringWithDetails({
    required this.recurring,
    this.category,
    this.wallet,
  });
}

// ─── DAOs ─────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [Wallets])
class WalletsDao extends DatabaseAccessor<AppDatabase>
    with _$WalletsDaoMixin {
  WalletsDao(super.db);

  Stream<List<Wallet>> watchAllWallets() =>
      select(wallets).watch();

  Future<List<Wallet>> getAllWallets() => select(wallets).get();

  Future<Wallet?> getDefaultWallet() async {
    final results = await (select(wallets)
          ..where((w) => w.isDefault.equals(true)))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertWallet(WalletsCompanion entry) =>
      into(wallets).insert(entry);

  Future<bool> updateWallet(Wallet entry) =>
      update(wallets).replace(entry);

  Future<void> updateBalance(int id, double newBalance) =>
      (update(wallets)..where((w) => w.id.equals(id))).write(
        WalletsCompanion(balance: Value(newBalance)),
      );

  Future<int> deleteWallet(int id) =>
      (delete(wallets)..where((w) => w.id.equals(id))).go();

  Future<void> seedDefaultWallets() async {
    final existing = await select(wallets).get();
    if (existing.isNotEmpty) return;
    final defaults = [
      WalletsCompanion.insert(
        name: 'Cash',
        type: 'cash',
        icon: 'cash',
        color: '#1D9E75',
        isDefault: const Value(true),
      ),
      WalletsCompanion.insert(
        name: 'GCash',
        type: 'gcash',
        icon: 'gcash',
        color: '#007DFF',
      ),
      WalletsCompanion.insert(
        name: 'Bank',
        type: 'bank',
        icon: 'bank',
        color: '#AB47BC',
      ),
    ];
    await batch((b) => b.insertAll(wallets, defaults));
  }
}

@DriftAccessor(tables: [Transactions, Categories, Wallets])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<TransactionWithDetails>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .join([
          leftOuterJoin(categories,
              categories.id.equalsExp(transactions.categoryId)),
          leftOuterJoin(
              wallets, wallets.id.equalsExp(transactions.walletId)),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                ))
            .toList());
  }

  Future<List<TransactionWithDetails>> getAllTransactionsWithDetails() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .join([
          leftOuterJoin(categories,
              categories.id.equalsExp(transactions.categoryId)),
          leftOuterJoin(
              wallets, wallets.id.equalsExp(transactions.walletId)),
        ])
        .get()
        .then((rows) => rows
            .map((row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                ))
            .toList());
  }

  Stream<List<TransactionWithDetails>> watchTransactionsForMonth(
      DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .join([
          leftOuterJoin(categories,
              categories.id.equalsExp(transactions.categoryId)),
          leftOuterJoin(
              wallets, wallets.id.equalsExp(transactions.walletId)),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                ))
            .toList());
  }

  Stream<List<TransactionWithDetails>> watchTransactionsForWallet(
      int walletId) {
    return (select(transactions)
          ..where((t) => t.walletId.equals(walletId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .join([
          leftOuterJoin(categories,
              categories.id.equalsExp(transactions.categoryId)),
          leftOuterJoin(
              wallets, wallets.id.equalsExp(transactions.walletId)),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                ))
            .toList());
  }

  Future<MonthlyTotals> getMonthlyTotals(DateTime month,
      {int? walletId}) async {
    final start = DateTime(month.year, month.month, 1);
    final end =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final query = select(transactions)
      ..where((t) {
        final dateFilter = t.date.isBetweenValues(start, end);
        if (walletId != null) {
          return dateFilter & t.walletId.equals(walletId);
        }
        return dateFilter;
      });
    final rows = await query.get();
    double income = 0, expense = 0;
    for (final t in rows) {
      if (t.type == 'income') {
        income += t.amount;
      } else if (t.type == 'expense') {
        expense += t.amount;
      }
    }
    return MonthlyTotals(income: income, expense: expense);
  }

  Future<Map<int, double>> getSpendingByCategory(DateTime month,
      {int? walletId}) async {
    final start = DateTime(month.year, month.month, 1);
    final end =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final query = select(transactions)
      ..where((t) {
        final base = t.date.isBetweenValues(start, end) &
            t.type.equals('expense');
        if (walletId != null) {
          return base & t.walletId.equals(walletId);
        }
        return base;
      });
    final rows = await query.get();
    final Map<int, double> result = {};
    for (final t in rows) {
      result[t.categoryId] =
          (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  Future<List<MonthlyTotals>> getLast6MonthsTotals() async {
    final List<MonthlyTotals> result = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final totals = await getMonthlyTotals(month);
      result.add(totals);
    }
    return result;
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  Stream<List<SavingsGoal>> watchAllGoals() =>
      (select(savingsGoals)
            ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
          .watch();

  Stream<List<SavingsGoal>> watchActiveGoals() =>
      (select(savingsGoals)
            ..where((g) => g.isCompleted.equals(false))
            ..orderBy([(g) => OrderingTerm.asc(g.deadline)]))
          .watch();

  Future<int> insertGoal(SavingsGoalsCompanion entry) =>
      into(savingsGoals).insert(entry);

  Future<bool> updateGoal(SavingsGoal entry) =>
      update(savingsGoals).replace(entry);

  Future<void> addToGoal(int id, double amount) async {
    final goal = await (select(savingsGoals)
          ..where((g) => g.id.equals(id)))
        .getSingle();
    final newAmount = goal.currentAmount + amount;
    await (update(savingsGoals)..where((g) => g.id.equals(id)))
        .write(
      SavingsGoalsCompanion(
        currentAmount: Value(newAmount),
        isCompleted: Value(newAmount >= goal.targetAmount),
      ),
    );
  }

  Future<void> subtractFromGoal(int id, double amount) async {
    final goal = await (select(savingsGoals)
          ..where((g) => g.id.equals(id)))
        .getSingle();
    final newAmount =
        (goal.currentAmount - amount).clamp(0.0, double.infinity);
    await (update(savingsGoals)..where((g) => g.id.equals(id)))
        .write(
      SavingsGoalsCompanion(
        currentAmount: Value(newAmount),
        isCompleted: Value(newAmount >= goal.targetAmount),
      ),
    );
  }

  Future<int> deleteGoal(int id) =>
      (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
}

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAllCategories() =>
      select(categories).watch();

  Future<List<Category>> getAllCategories() =>
      select(categories).get();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(Category entry) =>
      update(categories).replace(entry);

  Future<void> updateMonthlyLimit(int id, double? limit) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(monthlyLimit: Value(limit)),
      );

  Future<void> seedDefaultCategories() async {
    final existing = await select(categories).get();
    if (existing.isNotEmpty) return;
    final defaults = [
      CategoriesCompanion.insert(
          name: 'Food & Drinks', icon: 'food', color: '#FF6B6B'),
      CategoriesCompanion.insert(
          name: 'Transport', icon: 'transport', color: '#4ECDC4'),
      CategoriesCompanion.insert(
          name: 'Shopping', icon: 'shopping', color: '#A78BFA'),
      CategoriesCompanion.insert(
          name: 'Bills', icon: 'bills', color: '#F97316'),
      CategoriesCompanion.insert(
          name: 'Health', icon: 'health', color: '#1D9E75'),
      CategoriesCompanion.insert(
          name: 'Entertainment',
          icon: 'entertainment',
          color: '#F59E0B'),
      CategoriesCompanion.insert(
          name: 'Education', icon: 'education', color: '#3B82F6'),
      CategoriesCompanion.insert(
          name: 'Others', icon: 'other', color: '#888888'),
      CategoriesCompanion.insert(
          name: 'Salary',
          icon: 'salary',
          color: '#1D9E75',
          isIncome: const Value(true)),
      CategoriesCompanion.insert(
          name: 'Freelance',
          icon: 'freelance',
          color: '#4B9FFF',
          isIncome: const Value(true)),
      CategoriesCompanion.insert(
          name: 'Business',
          icon: 'business',
          color: '#A78BFA',
          isIncome: const Value(true)),
      CategoriesCompanion.insert(
          name: 'Allowance',
          icon: 'allowance',
          color: '#F59E0B',
          isIncome: const Value(true)),
    ];
    await batch((b) => b.insertAll(categories, defaults));
  }
}

@DriftAccessor(tables: [RecurringTransactions, Categories, Wallets])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.db);

  Stream<List<RecurringWithDetails>> watchAllRecurring() {
    return (select(recurringTransactions)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .join([
          leftOuterJoin(categories,
              categories.id.equalsExp(recurringTransactions.categoryId)),
          leftOuterJoin(wallets,
              wallets.id.equalsExp(recurringTransactions.walletId)),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => RecurringWithDetails(
                  recurring: row.readTable(recurringTransactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                ))
            .toList());
  }

  Future<int> insertRecurring(RecurringTransactionsCompanion entry) =>
      into(recurringTransactions).insert(entry);

  Future<bool> updateRecurring(RecurringTransaction entry) =>
      update(recurringTransactions).replace(entry);

  Future<int> deleteRecurring(int id) =>
      (delete(recurringTransactions)..where((r) => r.id.equals(id)))
          .go();

  Future<List<RecurringTransaction>> getActiveRecurring() =>
      (select(recurringTransactions)
            ..where((r) => r.isActive.equals(true)))
          .get();

  Future<void> markAsRun(int id) =>
      (update(recurringTransactions)
            ..where((r) => r.id.equals(id)))
          .write(
        RecurringTransactionsCompanion(
          lastRunAt: Value(DateTime.now()),
        ),
      );
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    SavingsGoals,
    RecurringTransactions,
  ],
  daos: [
    WalletsDao,
    TransactionsDao,
    SavingsGoalsDao,
    CategoriesDao,
    RecurringDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await walletsDao.seedDefaultWallets();
          await categoriesDao.seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(savingsGoals, savingsGoals.imagePath);
          }
        },
      );

  Future<int> processDueRecurring({DateTime? now}) async {
    final runAt = now ?? DateTime.now();
    final today = _dateOnly(runAt);

    return transaction(() async {
      final activeRecurring = await recurringDao.getActiveRecurring();
      var createdCount = 0;

      for (final recurring in activeRecurring) {
        final dueDates = _dueDatesFor(recurring, today);
        if (dueDates.isEmpty) continue;

        for (final dueDate in dueDates) {
          await transactionsDao.insertTransaction(
            TransactionsCompanion.insert(
              amount: recurring.amount,
              categoryId: recurring.categoryId,
              walletId: recurring.walletId,
              type: recurring.type,
              date: _transactionDateFor(dueDate, runAt),
              note: Value(recurring.note),
            ),
          );
          createdCount++;
        }

        await (update(recurringTransactions)
              ..where((r) => r.id.equals(recurring.id)))
            .write(
          RecurringTransactionsCompanion(
            lastRunAt: Value(_endOfDay(dueDates.last)),
          ),
        );
      }

      return createdCount;
    });
  }

  List<DateTime> _dueDatesFor(
    RecurringTransaction recurring,
    DateTime today,
  ) {
    final start = _dateOnly(recurring.startDate);
    final lastRun = recurring.lastRunAt == null
        ? null
        : _dateOnly(recurring.lastRunAt!);
    final earliest = lastRun == null
        ? start
        : _dateOnly(lastRun.add(const Duration(days: 1)));

    if (earliest.isAfter(today)) return const [];

    return switch (recurring.frequency) {
      'daily' => _dailyDueDates(earliest, today),
      'weekly' => _weeklyDueDates(
          earliest,
          today,
          recurring.dayOfWeek ?? start.weekday,
        ),
      'monthly' => _monthlyDueDates(
          earliest,
          today,
          recurring.dayOfMonth ?? start.day,
        ),
      _ => const <DateTime>[],
    };
  }

  List<DateTime> _dailyDueDates(DateTime earliest, DateTime today) {
    final dates = <DateTime>[];
    var cursor = earliest;
    while (!cursor.isAfter(today)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  List<DateTime> _weeklyDueDates(
    DateTime earliest,
    DateTime today,
    int dayOfWeek,
  ) {
    final dates = <DateTime>[];
    var cursor = earliest.add(
      Duration(days: (dayOfWeek - earliest.weekday) % 7),
    );
    while (!cursor.isAfter(today)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }
    return dates;
  }

  List<DateTime> _monthlyDueDates(
    DateTime earliest,
    DateTime today,
    int dayOfMonth,
  ) {
    final dates = <DateTime>[];
    var cursor = _scheduledMonthDate(
      earliest.year,
      earliest.month,
      dayOfMonth,
    );
    if (cursor.isBefore(earliest)) {
      cursor = _scheduledMonthDate(
        earliest.year,
        earliest.month + 1,
        dayOfMonth,
      );
    }

    while (!cursor.isAfter(today)) {
      dates.add(cursor);
      cursor = _scheduledMonthDate(
        cursor.year,
        cursor.month + 1,
        dayOfMonth,
      );
    }
    return dates;
  }

  DateTime _scheduledMonthDate(int year, int month, int dayOfMonth) {
    final normalizedMonth = DateTime(year, month);
    final lastDay =
        DateTime(normalizedMonth.year, normalizedMonth.month + 1, 0)
            .day;
    final scheduledDay = dayOfMonth.clamp(1, lastDay).toInt();
    return DateTime(
      normalizedMonth.year,
      normalizedMonth.month,
      scheduledDay,
    );
  }

  DateTime _transactionDateFor(DateTime dueDate, DateTime runAt) {
    if (_dateOnly(runAt) == dueDate) return runAt;
    return DateTime(dueDate.year, dueDate.month, dueDate.day, 12);
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file =
        File(p.join(dbFolder.path, 'budgetko_v2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
