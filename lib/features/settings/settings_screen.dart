import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/backup/backup_service.dart';
import '../export/export.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final budget = ref.watch(monthlyBudgetProvider);
    final notif = ref.watch(notificationSettingsProvider);
    final carryover = ref.watch(carryoverEnabledProvider);
    // Read from the package rather than hardcoded so it cannot drift away
    // from the version in pubspec.yaml.
    final version = ref.watch(appVersionProvider).valueOrNull ?? '—';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            16, 16, 16, 120),
        children: [
          // ── Profile card ───────────────────────────────────
          GlowContainer(
            glowColor: AppColors.teal,
            glowRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/android/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BudgetKo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Manage your money',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Budget section ─────────────────────────────────
          const _SectionTitle(title: 'Budget'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.income,
            title: 'Monthly income',
            subtitle: income > 0
                ? '₱${income.toStringAsFixed(0)}'
                : 'Not set',
            onTap: () =>
                _showIncomeDialog(context, ref, income),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.wallet_outlined,
            iconColor: AppColors.savings,
            title: 'Monthly budget',
            subtitle: budget > 0
                ? '₱${budget.toStringAsFixed(0)}'
                : 'Not set',
            onTap: () =>
                _showBudgetDialog(context, ref, budget),
          ),
          const SizedBox(height: 8),
          _SettingsSwitchTile(
            icon: Icons.autorenew,
            iconColor: AppColors.teal,
            title: 'Roll over unspent budget',
            subtitle: carryover
                ? 'Unspent category limits carry into next month'
                : 'Each month starts fresh at the set limit',
            value: carryover,
            onChanged: (v) => ref
                .read(carryoverEnabledProvider.notifier)
                .setEnabled(v),
          ),
          const SizedBox(height: 24),

          // ── Notifications section ──────────────────────────
          const _SectionTitle(title: 'Notifications'),
          const SizedBox(height: 8),

          _SettingsSwitchTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.warning,
            title: 'Notifications',
            subtitle: notif.enabled ? 'On' : 'Off',
            value: notif.enabled,
            onChanged: (v) => ref
                .read(notificationSettingsProvider.notifier)
                .setEnabled(v),
          ),
          if (notif.enabled) ...[
            const SizedBox(height: 8),
            _SettingsSwitchTile(
              icon: Icons.warning_amber_outlined,
              iconColor: AppColors.expense,
              title: 'Budget alerts',
              subtitle:
                  'Warn at 80% and 100% of limits',
              value: notif.overspend,
              onChanged: (v) => ref
                  .read(
                      notificationSettingsProvider.notifier)
                  .setOverspend(v),
            ),
            const SizedBox(height: 8),
            _SettingsSwitchTile(
              icon: Icons.alarm_outlined,
              iconColor: AppColors.teal,
              title: 'Daily reminder',
              subtitle: notif.daily
                  ? 'Every day at ${notif.dailyLabel}'
                  : 'Off',
              value: notif.daily,
              onChanged: (v) => ref
                  .read(
                      notificationSettingsProvider.notifier)
                  .setDaily(v),
            ),
            if (notif.daily) ...[
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.schedule_outlined,
                iconColor: AppColors.teal,
                title: 'Reminder time',
                subtitle: notif.dailyLabel,
                onTap: () => _showReminderTimePicker(
                    context, ref, notif),
              ),
            ],
            const SizedBox(height: 8),
            _SettingsSwitchTile(
              icon: Icons.repeat_outlined,
              iconColor: AppColors.savings,
              title: 'Recurring updates',
              subtitle:
                  'Notify when scheduled items are added',
              value: notif.recurring,
              onChanged: (v) => ref
                  .read(
                      notificationSettingsProvider.notifier)
                  .setRecurring(v),
            ),
            const SizedBox(height: 8),
            _SettingsSwitchTile(
              icon: Icons.flag_outlined,
              iconColor: AppColors.income,
              title: 'Goal deadlines',
              subtitle:
                  'Remind when a goal is due soon',
              value: notif.goals,
              onChanged: (v) => ref
                  .read(
                      notificationSettingsProvider.notifier)
                  .setGoals(v),
            ),
            const SizedBox(height: 8),
            _SettingsSwitchTile(
              icon: Icons.bolt_outlined,
              iconColor: AppColors.teal,
              title: 'Quick-add confirmations',
              subtitle:
                  'Notify each time a transaction is saved',
              value: notif.quickAdd,
              onChanged: (v) => ref
                  .read(
                      notificationSettingsProvider.notifier)
                  .setQuickAdd(v),
            ),
          ],
          const SizedBox(height: 24),

          // ── Backup & restore ─────────────────────────────
          const _SectionTitle(title: 'Backup & Restore'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.backup_outlined,
            iconColor: AppColors.teal,
            title: 'Back up all data',
            subtitle:
                'Save wallets, categories, transactions, goals and settings',
            onTap: () => _backupData(context, ref),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.restore_outlined,
            iconColor: AppColors.savings,
            title: 'Restore from backup',
            subtitle: 'Replace all current data with a backup file',
            onTap: () => _restoreData(context, ref),
          ),
          const SizedBox(height: 24),

          // ── Reports ──────────────────────────────────────
          const _SectionTitle(title: 'Reports'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.table_view_outlined,
            iconColor: AppColors.teal,
            title: 'Export to Excel',
            subtitle: 'Transactions only, for viewing in a spreadsheet',
            onTap: () => _exportExcel(context, ref),
          ),
          const SizedBox(height: 24),

          // ── Danger zone ──────────────────────────────────
          const _SectionTitle(title: 'Danger zone'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: AppColors.expense,
            title: 'Clear all data',
            subtitle: 'Delete all transactions and goals',
            onTap: () => _showClearDialog(context, ref),
            titleColor: AppColors.expense,
          ),
          const SizedBox(height: 24),

          // ── About section ──────────────────────────────────
          const _SectionTitle(title: 'About'),
          const SizedBox(height: 8),

          GlowContainer(
            glowColor: AppColors.bgSurface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const _InfoRow(
                    label: 'App', value: 'BudgetKo'),
                const Divider(height: 16),
                // Read from the package rather than hardcoded so it
                // cannot drift away from the version in pubspec.yaml.
                _InfoRow(label: 'Version', value: version),
                const Divider(height: 16),
                const _InfoRow(
                    label: 'Database',
                    value: 'SQLite (drift)'),
                const Divider(height: 16),
                const _InfoRow(
                    label: 'Framework',
                    value: 'Flutter'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomeDialog(
      BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Monthly income',
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
          style: const TextStyle(
              color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₱ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null) {
                ref
                    .read(monthlyIncomeProvider.notifier)
                    .setIncome(v);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Monthly budget',
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
          style: const TextStyle(
              color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₱ ',
            hintText: 'e.g. 15000',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) {
                ref
                    .read(monthlyBudgetProvider.notifier)
                    .setBudget(v);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData(
      BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text('Creating backup...',
            style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
    try {
      final path =
          await BackupService.instance.createBackup(db);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 6),
          content: Text(
            'Backup saved to $path',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          content: Text(
            'Backup failed: $e',
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
    }
  }

  Future<void> _restoreData(
      BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final raw = await BackupService.instance.pickBackupFile();
    if (raw == null) return;

    BackupValidation validation;
    try {
      validation = BackupService.instance.validate(raw);
    } on BackupException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 5),
          content: Text(
            e.message,
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
      return;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          content: Text(
            'Could not read that file: $e',
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardLight,
        title: const Text('Restore this backup?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup from ${Formatters.dateFull(validation.exportedAt)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${validation.transactions} transactions · '
              '${validation.wallets} wallets\n'
              '${validation.categories} categories · '
              '${validation.goals} goals · '
              '${validation.recurring} recurring',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Everything currently in the app will be replaced. '
              'This cannot be undone.',
              style: TextStyle(
                color: AppColors.expense,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text('Restoring...',
            style: TextStyle(color: AppColors.textPrimary)),
      ),
    );

    try {
      final count = await BackupService.instance
          .restore(ref.read(databaseProvider), validation);
      if (!context.mounted) return;
      ref
        ..invalidate(categoriesProvider)
        ..invalidate(allWalletsProvider)
        ..invalidate(allGoalsProvider)
        ..invalidate(allRecurringProvider)
        ..invalidate(monthlyTotalsProvider)
        ..invalidate(spendingByCategoryProvider)
        ..invalidate(categoryBudgetStatusProvider)
        ..invalidate(spendingInsightsProvider)
        ..invalidate(last6MonthsProvider)
        ..invalidate(allTransactionsProvider)
        ..invalidate(transactionsForMonthProvider)
        ..invalidate(monthlyBudgetProvider)
        ..invalidate(monthlyIncomeProvider)
        ..invalidate(carryoverEnabledProvider)
        ..invalidate(notificationSettingsProvider);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 5),
          content: Text(
            'Restored $count records',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 5),
          content: Text(
            'Restore failed: $e',
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
    }
  }

  void _showClearDialog(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Clear all data?',
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently delete all transactions, goals, and settings. This cannot be undone.',
          style:
              TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(
      BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          'Exporting transactions...',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );

    try {
      final transactions = await ref
          .read(transactionsDaoProvider)
          .getAllTransactionsWithDetails();
      final result =
          await ExcelExporter().exportTransactions(transactions);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 6),
          content: Text(
            'Exported ${result.rowCount} transactions to ${result.path}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          content: Text(
            'Export failed: $e',
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
    }
  }

  Future<void> _showReminderTimePicker(
      BuildContext context,
      WidgetRef ref,
      NotificationSettings notif) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: notif.dailyHour,
          minute: notif.dailyMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.teal,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref
          .read(notificationSettingsProvider.notifier)
          .setDailyTime(picked.hour, picked.minute);
    }
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlowContainer(
        glowColor: AppColors.bgSurface,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ??
                          AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      glowColor: AppColors.bgSurface,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.teal,
            activeThumbColor: Colors.white,
            inactiveThumbColor:
                AppColors.textSecondary,
            inactiveTrackColor: AppColors.bgSurface,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
