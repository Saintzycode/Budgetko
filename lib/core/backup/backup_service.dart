import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../notifications/notification_triggers.dart';
import '../../data/repositories/providers.dart';

const String kBackupFormat = 'budgetko-backup';
const int kBackupSchemaVersion = 1;

class BackupValidation {
  final Map<String, dynamic> payload;
  final int wallets;
  final int categories;
  final int transactions;
  final int goals;
  final int recurring;
  final DateTime exportedAt;

  const BackupValidation({
    required this.payload,
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.goals,
    required this.recurring,
    required this.exportedAt,
  });

  int get totalRecords =>
      wallets + categories + transactions + goals + recurring;
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const MethodChannel _channel =
      MethodChannel('budgetko/downloads');

  // ── Export ───────────────────────────────────────────────────────────────────

  Future<String> createBackup(AppDatabase db) async {
    final wallets = await db.walletsDao.getAllWallets();
    final categories = await db.categoriesDao.getAllCategories();
    final transactions =
        await db.transactionsDao.getAllRawTransactions();
    final goals = await db.savingsGoalsDao.getAllGoals();
    final recurring = await db.recurringDao.getAllRecurring();
    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'format': kBackupFormat,
      'schemaVersion': kBackupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'wallets': [
        for (final w in wallets)
          {
            'id': w.id,
            'name': w.name,
            'type': w.type,
            'icon': w.icon,
            'color': w.color,
            'balance': w.balance,
            'isDefault': w.isDefault,
            'createdAt': w.createdAt.toIso8601String(),
          }
      ],
      'categories': [
        for (final c in categories)
          {
            'id': c.id,
            'name': c.name,
            'icon': c.icon,
            'color': c.color,
            'monthlyLimit': c.monthlyLimit,
            'isIncome': c.isIncome,
            'createdAt': c.createdAt.toIso8601String(),
          }
      ],
      'transactions': [
        for (final t in transactions)
          {
            'id': t.id,
            'amount': t.amount,
            'note': t.note,
            'categoryId': t.categoryId,
            'walletId': t.walletId,
            'type': t.type,
            'date': t.date.toIso8601String(),
            'createdAt': t.createdAt.toIso8601String(),
          }
      ],
      'goals': [
        for (final g in goals)
          {
            'id': g.id,
            'name': g.name,
            'targetAmount': g.targetAmount,
            'currentAmount': g.currentAmount,
            'deadline': g.deadline?.toIso8601String(),
            'color': g.color,
            'icon': g.icon,
            'isCompleted': g.isCompleted,
            'createdAt': g.createdAt.toIso8601String(),
          }
      ],
      'recurring': [
        for (final r in recurring)
          {
            'id': r.id,
            'amount': r.amount,
            'note': r.note,
            'categoryId': r.categoryId,
            'walletId': r.walletId,
            'type': r.type,
            'frequency': r.frequency,
            'dayOfWeek': r.dayOfWeek,
            'dayOfMonth': r.dayOfMonth,
            'startDate': r.startDate.toIso8601String(),
            'lastRunAt': r.lastRunAt?.toIso8601String(),
            'isActive': r.isActive,
            'createdAt': r.createdAt.toIso8601String(),
          }
      ],
      'settings': {
        'monthlyIncome': prefs.getDouble('monthly_income') ?? 0,
        'monthlyBudget': prefs.getDouble('monthly_budget') ?? 0,
        'carryover': prefs.getBool(kCarryoverEnabledKey) ?? false,
        'notifMaster': prefs.getBool(NotifKeys.master) ?? true,
        'notifOverspend': prefs.getBool(NotifKeys.overspend) ?? true,
        'notifDaily': prefs.getBool(NotifKeys.daily) ?? true,
        'notifDailyHour': prefs.getInt(NotifKeys.dailyHour) ?? 20,
        'notifDailyMinute': prefs.getInt(NotifKeys.dailyMinute) ?? 0,
        'notifRecurring': prefs.getBool(NotifKeys.recurring) ?? true,
        'notifGoals': prefs.getBool(NotifKeys.goals) ?? true,
        'notifQuickAdd': prefs.getBool(NotifKeys.quickAdd) ?? true,
      },
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'budgetko-backup-$stamp.json';
    return _saveFile(fileName, json, 'application/json');
  }

  Future<String> _saveFile(
      String fileName, String content, String mimeType) async {
    if (Platform.isAndroid) {
      final path = await _channel.invokeMethod<String>(
        'saveWorkbook',
        {
          'fileName': fileName,
          'content': content,
          'mimeType': mimeType,
        },
      );
      if (path == null || path.isEmpty) {
        throw const BackupException('Could not save the backup file.');
      }
      return path;
    }

    final downloads = await getDownloadsDirectory();
    final base = downloads ?? await getApplicationDocumentsDirectory();
    final directory =
        Directory(p.join(base.path, 'BudgetKo exports'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  // ── Import ───────────────────────────────────────────────────────────────────

  Future<String?> pickBackupFile() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('pickBackupFile');
    }
    return null;
  }

  /// Parses and sanity-checks a backup without touching the database.
  BackupValidation validate(String raw) {
    if (raw.trim().isEmpty) {
      throw const BackupException('The selected file is empty.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw BackupException('Not a valid backup file: ${e.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException(
          'Unexpected backup structure at the top level.');
    }

    if (decoded['format'] != kBackupFormat) {
      throw const BackupException(
          'This is not a BudgetKo backup file.');
    }

    final version = decoded['schemaVersion'];
    if (version is! int) {
      throw const BackupException('Backup is missing a schema version.');
    }
    if (version > kBackupSchemaVersion) {
      throw BackupException(
        'This backup was made by a newer version of BudgetKo '
        '(schema $version). Please update the app first.',
      );
    }

    final wallets = _listOf(decoded, 'wallets');
    final categories = _listOf(decoded, 'categories');
    final transactions = _listOf(decoded, 'transactions');
    final goals = _listOf(decoded, 'goals');
    final recurring = _listOf(decoded, 'recurring');

    final walletIds =
        wallets.map((e) => _int(e, 'id')).toSet();
    final categoryIds =
        categories.map((e) => _int(e, 'id')).toSet();

    for (final raw_ in transactions) {
      final walletId = _int(raw_, 'walletId');
      final categoryId = _int(raw_, 'categoryId');
      if (!walletIds.contains(walletId)) {
        throw BackupException(
            'Transaction references wallet id $walletId, which is missing '
            'from the backup.');
      }
      if (!categoryIds.contains(categoryId)) {
        throw BackupException(
            'Transaction references category id $categoryId, which is missing '
            'from the backup.');
      }
    }

    for (final raw_ in recurring) {
      final walletId = _int(raw_, 'walletId');
      final categoryId = _int(raw_, 'categoryId');
      if (!walletIds.contains(walletId)) {
        throw BackupException(
            'Recurring item references wallet id $walletId, which is missing '
            'from the backup.');
      }
      if (!categoryIds.contains(categoryId)) {
        throw BackupException(
            'Recurring item references category id $categoryId, which is '
            'missing from the backup.');
      }
    }

    final exportedAtRaw = decoded['exportedAt'];
    final exportedAt = exportedAtRaw is String
        ? (DateTime.tryParse(exportedAtRaw) ?? DateTime.now())
        : DateTime.now();

    return BackupValidation(
      payload: decoded,
      wallets: wallets.length,
      categories: categories.length,
      transactions: transactions.length,
      goals: goals.length,
      recurring: recurring.length,
      exportedAt: exportedAt,
    );
  }

  List<Map<String, dynamic>> _listOf(
      Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return const [];
    if (value is! List) {
      throw BackupException('"$key" is not a list in this backup.');
    }
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        throw BackupException('"$key" contains a malformed entry.');
      }
      result.add(item);
    }
    return result;
  }

  int _int(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw BackupException('Missing or invalid "$key" value.');
  }

  double _double(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    throw BackupException('Missing or invalid "$key" value.');
  }

  bool _bool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw BackupException('Missing or invalid "$key" value.');
  }

  String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    throw BackupException('Missing or invalid "$key" value.');
  }

  String? _stringOrNull(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is String) return value;
    throw BackupException('Invalid "$key" value.');
  }

  double? _doubleOrNull(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw BackupException('Invalid "$key" value.');
  }

  int? _intOrNull(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is num) return value.toInt();
    throw BackupException('Invalid "$key" value.');
  }

  DateTime _date(Map<String, dynamic> map, String key) {
    final value = _string(map, key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupException('Invalid date in "$key".');
    }
    return parsed;
  }

  DateTime? _dateOrNull(Map<String, dynamic> map, String key) {
    final value = _stringOrNull(map, key);
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupException('Invalid date in "$key".');
    }
    return parsed;
  }

  /// Replaces all existing data with the contents of a validated backup.
  ///
  /// Runs inside a single transaction so a failure part-way through cannot
  /// leave the database half-wiped.
  Future<int> restore(AppDatabase db, BackupValidation validation) async {
    final data = validation.payload;

    final wallets = _listOf(data, 'wallets');
    final categories = _listOf(data, 'categories');
    final transactions = _listOf(data, 'transactions');
    final goals = _listOf(data, 'goals');
    final recurring = _listOf(data, 'recurring');

    await db.transaction(() async {
      // Children first so foreign keys never dangle.
      await db.transactionsDao.deleteAllTransactions();
      await db.recurringDao.deleteAllRecurring();
      await db.savingsGoalsDao.deleteAllGoals();
      await db.walletsDao.deleteAllWallets();
      await db.categoriesDao.deleteAllCategories();

      for (final w in wallets) {
        await db.walletsDao.insertWallet(
          WalletsCompanion(
            id: Value(_int(w, 'id')),
            name: Value(_string(w, 'name')),
            type: Value(_string(w, 'type')),
            icon: Value(_string(w, 'icon')),
            color: Value(_string(w, 'color')),
            balance: Value(_double(w, 'balance')),
            isDefault: Value(_bool(w, 'isDefault')),
            createdAt: Value(_date(w, 'createdAt')),
          ),
        );
      }

      for (final c in categories) {
        await db.categoriesDao.insertCategory(
          CategoriesCompanion(
            id: Value(_int(c, 'id')),
            name: Value(_string(c, 'name')),
            icon: Value(_string(c, 'icon')),
            color: Value(_string(c, 'color')),
            monthlyLimit: Value(_doubleOrNull(c, 'monthlyLimit')),
            isIncome: Value(_bool(c, 'isIncome')),
            createdAt: Value(_date(c, 'createdAt')),
          ),
        );
      }

      for (final t in transactions) {
        await db.transactionsDao.insertTransaction(
          TransactionsCompanion(
            id: Value(_int(t, 'id')),
            amount: Value(_double(t, 'amount')),
            note: Value(_stringOrNull(t, 'note')),
            categoryId: Value(_int(t, 'categoryId')),
            walletId: Value(_int(t, 'walletId')),
            type: Value(_string(t, 'type')),
            date: Value(_date(t, 'date')),
            createdAt: Value(_date(t, 'createdAt')),
          ),
        );
      }

      for (final g in goals) {
        await db.savingsGoalsDao.insertGoal(
          SavingsGoalsCompanion(
            id: Value(_int(g, 'id')),
            name: Value(_string(g, 'name')),
            targetAmount: Value(_double(g, 'targetAmount')),
            currentAmount: Value(_double(g, 'currentAmount')),
            deadline: Value(_dateOrNull(g, 'deadline')),
            color: Value(_string(g, 'color')),
            icon: Value(_string(g, 'icon')),
            // Local image files do not survive an app reinstall, so the
            // path is intentionally dropped rather than left dangling.
            imagePath: const Value(null),
            isCompleted: Value(_bool(g, 'isCompleted')),
            createdAt: Value(_date(g, 'createdAt')),
          ),
        );
      }

      for (final r in recurring) {
        await db.recurringDao.insertRecurring(
          RecurringTransactionsCompanion(
            id: Value(_int(r, 'id')),
            amount: Value(_double(r, 'amount')),
            note: Value(_stringOrNull(r, 'note')),
            categoryId: Value(_int(r, 'categoryId')),
            walletId: Value(_int(r, 'walletId')),
            type: Value(_string(r, 'type')),
            frequency: Value(_string(r, 'frequency')),
            dayOfWeek: Value(_intOrNull(r, 'dayOfWeek')),
            dayOfMonth: Value(_intOrNull(r, 'dayOfMonth')),
            startDate: Value(_date(r, 'startDate')),
            lastRunAt: Value(_dateOrNull(r, 'lastRunAt')),
            isActive: Value(_bool(r, 'isActive')),
            createdAt: Value(_date(r, 'createdAt')),
          ),
        );
      }
    });

    await _restoreSettings(data);
    debugPrint(
        'Backup restored: ${validation.totalRecords} records');
    return validation.totalRecords;
  }

  Future<void> _restoreSettings(Map<String, dynamic> data) async {
    final raw = data['settings'];
    if (raw is! Map<String, dynamic>) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final income = raw['monthlyIncome'];
      if (income is num) {
        await prefs.setDouble('monthly_income', income.toDouble());
      }
      final budget = raw['monthlyBudget'];
      if (budget is num) {
        await prefs.setDouble('monthly_budget', budget.toDouble());
      }
      final carryover = raw['carryover'];
      if (carryover is bool) {
        await prefs.setBool(kCarryoverEnabledKey, carryover);
      }
      final notifKeys = <String, String>{
        'notifMaster': NotifKeys.master,
        'notifOverspend': NotifKeys.overspend,
        'notifDaily': NotifKeys.daily,
        'notifRecurring': NotifKeys.recurring,
        'notifGoals': NotifKeys.goals,
        'notifQuickAdd': NotifKeys.quickAdd,
      };
      for (final entry in notifKeys.entries) {
        final value = raw[entry.key];
        if (value is bool) {
          await prefs.setBool(entry.value, value);
        }
      }
      final hour = raw['notifDailyHour'];
      if (hour is num) {
        await prefs.setInt(NotifKeys.dailyHour, hour.toInt());
      }
      final minute = raw['notifDailyMinute'];
      if (minute is num) {
        await prefs.setInt(NotifKeys.dailyMinute, minute.toInt());
      }
    } catch (e) {
      debugPrint('Could not restore settings: $e');
    }
  }
}
