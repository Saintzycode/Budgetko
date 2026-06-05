import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../core/router.dart';
import '../export/export.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final budget = ref.watch(monthlyBudgetProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu,
                color: AppColors.textPrimary),
            onPressed: () => openDrawer(),
          ),
        ),
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
          const SizedBox(height: 24),

          // ── Data section ───────────────────────────────────
          const _SectionTitle(title: 'Data'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.download_outlined,
            iconColor: AppColors.teal,
            title: 'Export to Excel',
            subtitle: 'Download your transactions as .xls',
            onTap: () => _exportExcel(context, ref),
          ),
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

          const GlowContainer(
            glowColor: AppColors.bgSurface,
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                    label: 'App', value: 'BudgetKo'),
                 Divider(height: 16),
                _InfoRow(
                    label: 'Version', value: '2.0.0'),
                 Divider(height: 16),
                _InfoRow(
                    label: 'Database',
                    value: 'SQLite (drift)'),
                 Divider(height: 16),
                _InfoRow(
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
