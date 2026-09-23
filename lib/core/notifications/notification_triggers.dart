import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/providers.dart';
import '../budget/budget_status.dart';
import '../utils/formatters.dart';
import 'notification_service.dart';

abstract class NotifKeys {
  static const master = 'notif_master';
  static const overspend = 'notif_overspend';
  static const daily = 'notif_daily';
  static const dailyHour = 'notif_daily_hour';
  static const dailyMinute = 'notif_daily_minute';
  static const recurring = 'notif_recurring';
  static const goals = 'notif_goals';
  static const quickAdd = 'notif_quickadd';
}

Future<bool> _togglesOn(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getBool(NotifKeys.master) ?? true) &&
      (prefs.getBool(key) ?? true);
}

/// Fires once per category per month at 80% and 100% of its limit.
///
/// When budget carry-over is enabled the effective limit includes the
/// unspent amount rolled over from the previous month, so warnings match
/// what the dashboard and Spending Limits screens show.
Future<void> checkBudgetAlerts(AppDatabase db) async {
  try {
    if (!await _togglesOn(NotifKeys.overspend)) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);
    final monthKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}';
    final carryover =
        (prefs.getBool(kCarryoverEnabledKey) ?? false);

    final cats = await db.categoriesDao.getAllCategories();
    final spending = await db.transactionsDao
        .getSpendingByCategory(currentMonth);
    final previousSpending = await db.transactionsDao
        .getSpendingByCategory(previousMonth);
    final hasPriorData = previousSpending.isNotEmpty;

    for (final cat in cats) {
      if (cat.isIncome) continue;
      final baseLimit = cat.monthlyLimit;
      if (baseLimit == null || baseLimit <= 0) continue;
      final limit = baseLimit +
          computeRollover(
            baseLimit: baseLimit,
            previousSpent: previousSpending[cat.id] ?? 0,
            carryoverEnabled: carryover,
            hasPriorData: hasPriorData,
          );
      final spent = spending[cat.id] ?? 0.0;
      final key80 =
          'budget_alert_${cat.id}_${monthKey}_80';
      final key100 =
          'budget_alert_${cat.id}_${monthKey}_100';
      if (spent > limit &&
          !(prefs.getBool(key100) ?? false)) {
        final overTitle = '${cat.name} over budget';
        final overBody =
            '${Formatters.currencyCompact(spent)} spent of ${Formatters.currencyCompact(limit)} limit.';
        await logInbox(db,
            title: overTitle,
            body: overBody,
            type: 'overspend',
            payload: 'overspend:${cat.id}');
        await NotificationService.instance.showInstant(
          id: NotificationService.overspendId(
              cat.id, true),
          title: overTitle,
          body: overBody,
          payload: 'overspend:${cat.id}',
        );
        await prefs.setBool(key100, true);
        await prefs.setBool(key80, true);
      } else if (spent >= limit * 0.8 &&
          !(prefs.getBool(key80) ?? false)) {
        final warnTitle =
            '${cat.name} at 80% of budget';
        final warnBody =
            '${Formatters.currencyCompact(spent)} spent of ${Formatters.currencyCompact(limit)} limit.';
        await logInbox(db,
            title: warnTitle,
            body: warnBody,
            type: 'overspend',
            payload: 'overspend:${cat.id}');
        await NotificationService.instance.showInstant(
          id: NotificationService.overspendId(
              cat.id, false),
          title: warnTitle,
          body: warnBody,
          payload: 'overspend:${cat.id}',
        );
        await prefs.setBool(key80, true);
      }
    }
  } catch (e) {
    debugPrint('checkBudgetAlerts failed: $e');
  }
}

/// Notifies once per day per goal due within 3 days (or overdue).
Future<void> checkGoalDeadlines(AppDatabase db) async {
  try {
    if (!await _togglesOn(NotifKeys.goals)) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final goals =
        await db.savingsGoalsDao.watchActiveGoals().first;
    for (final goal in goals) {
      final deadline = goal.deadline;
      if (deadline == null || goal.isCompleted) continue;
      final day = DateTime(
          deadline.year, deadline.month, deadline.day);
      final daysLeft = day.difference(today).inDays;
      if (daysLeft > 3) continue;
      final key = 'goal_alert_${goal.id}_$todayKey';
      if (prefs.getBool(key) ?? false) continue;
      final remaining =
          (goal.targetAmount - goal.currentAmount)
              .clamp(0.0, double.infinity);
      final when = daysLeft < 0
          ? 'was due ${-daysLeft}d ago'
          : daysLeft == 0
              ? 'due today'
              : 'due in $daysLeft day${daysLeft == 1 ? '' : 's'}';
      final goalTitle = '${goal.name} $when';
      final goalBody =
          '${Formatters.currencyCompact(remaining)} to go of ${Formatters.currencyCompact(goal.targetAmount)}.';
      await logInbox(db,
          title: goalTitle,
          body: goalBody,
          type: 'goal',
          payload: 'goal:${goal.id}');
      await NotificationService.instance.showInstant(
        id: NotificationService.goalId(goal.id),
        title: goalTitle,
        body: goalBody,
        payload: 'goal:${goal.id}',
      );
      await prefs.setBool(key, true);
    }
  } catch (e) {
    debugPrint('checkGoalDeadlines failed: $e');
  }
}

Future<void> notifyQuickAdd({
  required AppDatabase db,
  required double amount,
  required String categoryName,
  required String type,
}) async {
  try {
    if (!await _togglesOn(NotifKeys.quickAdd)) return;
    final title =
        '${Formatters.currency(amount)} · $categoryName';
    final body = type == 'expense'
        ? 'Expense saved.'
        : 'Income saved.';
    await logInbox(db,
        title: title,
        body: body,
        type: 'quickadd',
        payload: 'quickadd');
    await NotificationService.instance.showInstant(
      id: NotificationService.quickAddId,
      title: title,
      body: body,
      payload: 'quickadd',
    );
  } catch (e) {
    debugPrint('notifyQuickAdd failed: $e');
  }
}

Future<void> notifyRecurring(
    AppDatabase db, int count) async {
  try {
    if (!await _togglesOn(NotifKeys.recurring)) return;
    final title = count == 1
        ? 'Recurring transaction added'
        : '$count recurring transactions added';
    const body =
        'Your scheduled items are up to date.';
    await logInbox(db,
        title: title,
        body: body,
        type: 'recurring',
        payload: 'recurring');
    await NotificationService.instance.showInstant(
      id: NotificationService.recurringId,
      title: title,
      body: body,
      payload: 'recurring',
    );
  } catch (e) {
    debugPrint('notifyRecurring failed: $e');
  }
}

Future<void> refreshDailyReminder() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        (prefs.getBool(NotifKeys.master) ?? true) &&
            (prefs.getBool(NotifKeys.daily) ?? true);
    if (!enabled) {
      await NotificationService.instance
          .cancelDailyReminder();
      return;
    }
    await NotificationService.instance
        .scheduleDailyReminder(
      hour: prefs.getInt(NotifKeys.dailyHour) ?? 20,
      minute: prefs.getInt(NotifKeys.dailyMinute) ?? 0,
    );
  } catch (e) {
    debugPrint('refreshDailyReminder failed: $e');
  }
}

Future<void> logInbox(
  AppDatabase db, {
  required String title,
  required String body,
  required String type,
  String? payload,
}) async {
  try {
    await db.notificationsDao.insertNotification(
      AppNotificationsCompanion.insert(
        title: title,
        body: body,
        type: type,
        payload: payload == null
            ? const Value.absent()
            : Value(payload),
      ),
    );
  } catch (e) {
    debugPrint('logInbox failed: $e');
  }
}

String? notificationRouteFor(String? payload) {
  if (payload == null) return null;
  if (payload.startsWith('overspend:')) return '/alerts';
  if (payload.startsWith('goal:')) return '/goals';
  if (payload == 'quickadd' || payload == 'recurring') {
    return '/transactions';
  }
  if (payload == 'daily') return '/';
  return null;
}
