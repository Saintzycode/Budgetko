import '../../core/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);
    final walletsAsync = ref.watch(allWalletsProvider);
    final budget = ref.watch(monthlyBudgetProvider);
    final selectedWallet = ref.watch(selectedWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/android/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'BudgetKo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _pickMonth(context, ref, month),
            icon: const Icon(Icons.calendar_month_outlined,
                size: 14, color: AppColors.teal),
            label: Text(
              Formatters.monthShort(month),
              style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: AppColors.bgCard,
        onRefresh: () async {
          ref.invalidate(monthlyTotalsProvider);
          ref.invalidate(transactionsForMonthProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Wallet chips ───────────────────────────────────────
            walletsAsync.when(
              data: (wallets) => _WalletChips(
                wallets: wallets,
                selectedId: selectedWallet,
                onSelect: (id) => ref
                    .read(selectedWalletProvider.notifier)
                    .state = id,
              ),
              loading: () => const _WalletChipsSkeleton(),
              error: (e, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // ── Balance card ───────────────────────────────────────
            totalsAsync.when(
              data: (totals) => _BalanceCard(
                totals: totals,
                month: month,
              ),
              loading: () => const _LoadingCard(height: 160),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // ── Budget card ────────────────────────────────────────
            if (budget > 0)
              totalsAsync.when(
                data: (totals) => _BudgetCard(
                  budget: budget,
                  spent: totals.expense,
                ),
                loading: () => const _LoadingCard(height: 104),
                error: (e, _) => const SizedBox(),
              ),
            if (budget > 0) const SizedBox(height: 16),

            // ── Spending chart ─────────────────────────────────────
            const _SectionHeader(title: 'Spending breakdown'),
            const SizedBox(height: 8),
            const _SpendingChart(),
            const SizedBox(height: 16),

            // ── Savings goals ──────────────────────────────────────
            _SectionHeader(
              title: 'Savings goals',
              trailing: TextButton(
                onPressed: () => context.go('/goals'),
                child: const Text('See all',
                    style: TextStyle(
                        color: AppColors.teal, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            goalsAsync.when(
              data: (goals) => goals.isEmpty
                  ? _EmptyState(
                      icon: Icons.savings_outlined,
                      message: 'No savings goals yet',
                    )
                  : Column(
                      children: goals
                          .take(2)
                          .map((g) => _GoalCard(goal: g))
                          .toList(),
                    ),
              loading: () => const _LoadingCard(height: 80),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // ── Recent transactions ────────────────────────────────
            _SectionHeader(
              title: 'Recent transactions',
              trailing: TextButton(
                onPressed: () => context.go('/transactions'),
                child: const Text('See all',
                    style: TextStyle(
                        color: AppColors.teal, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (txns) => txns.isEmpty
                  ? _EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'No transactions this month',
                    )
                  : Column(
                      children: txns
                          .take(5)
                          .map((t) => _TransactionTile(item: t))
                          .toList(),
                    ),
              loading: () => const _LoadingCard(height: 200),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
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
      ref.read(selectedMonthProvider.notifier).state =
          DateTime(picked.year, picked.month);
    }
  }
}

// ── Wallet chips ───────────────────────────────────────────────────────────────

class _WalletChips extends StatelessWidget {
  final List<Wallet> wallets;
  final int? selectedId;
  final Function(int?) onSelect;

  const _WalletChips({
    required this.wallets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // All wallets chip
          GestureDetector(
            onTap: () => onSelect(null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selectedId == null
                    ? AppColors.teal
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedId == null
                      ? AppColors.teal
                      : AppColors.bgSurface,
                  width: 0.5,
                ),
              ),
              child: Text(
                'All',
                style: TextStyle(
                  color: selectedId == null
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Individual wallet chips
          ...wallets.map((w) {
            final isSelected = selectedId == w.id;
            final color = AppColors.fromHex(w.color);
            return GestureDetector(
              onTap: () => onSelect(w.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppColors.bgSurface,
                    width: isSelected ? 1 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _walletIcon(w.type),
                      size: 14,
                      color: isSelected
                          ? color
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      w.name,
                      style: TextStyle(
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _walletIcon(String type) {
    return switch (type) {
      'cash' => Icons.payments_outlined,
      'gcash' => Icons.phone_android_outlined,
      'bank' => Icons.account_balance_outlined,
      _ => Icons.wallet_outlined,
    };
  }
}

class _WalletChipsSkeleton extends StatelessWidget {
  const _WalletChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: _SkeletonPulse(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: const [
            _SkeletonBlock(width: 54, height: 36, radius: 20),
            SizedBox(width: 8),
            _SkeletonBlock(width: 96, height: 36, radius: 20),
            SizedBox(width: 8),
            _SkeletonBlock(width: 118, height: 36, radius: 20),
          ],
        ),
      ),
    );
  }
}

// ── Balance card ───────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final MonthlyTotals totals;
  final DateTime month;

  const _BalanceCard({
    required this.totals,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      glowColor: AppColors.teal,
      glowRadius: 30,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.month(month),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Net Balance',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(totals.savings),
            style: TextStyle(
              color: totals.savings >= 0
                  ? AppColors.teal
                  : AppColors.expense,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Savings rate: ${Formatters.percent(totals.savingsRate)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Income vs Expense row
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  amount: totals.income,
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Expenses',
                  amount: totals.expense,
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11)),
                Text(
                  Formatters.currencyCompact(amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Budget card ────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final double budget;
  final double spent;

  const _BudgetCard({required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final progress = (spent / budget).clamp(0.0, 1.0);
    final isOver = spent > budget;
    final isWarning = progress >= 0.8 && !isOver;
    final color = isOver
        ? AppColors.expense
        : isWarning
            ? AppColors.warning
            : AppColors.teal;

    return GlowContainer(
      glowColor: color,
      glowRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: color, size: 16),
                  const SizedBox(width: 8),
                  const Text('Monthly Budget',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withOpacity(0.3), width: 0.5),
                ),
                child: Text(
                  isOver
                      ? 'Over budget!'
                      : isWarning
                          ? '80% used'
                          : 'On track ✓',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${Formatters.currency(spent)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                'Budget: ${Formatters.currency(budget)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Spending chart ─────────────────────────────────────────────────────────────

class _SpendingChart extends ConsumerWidget {
  const _SpendingChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return spendingAsync.when(
      data: (spending) => categoriesAsync.when(
        data: (cats) {
          if (spending.isEmpty) {
            return _EmptyState(
              icon: Icons.pie_chart_outline,
              message: 'No spending data yet',
            );
          }

          final sortedEntries = spending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final total = sortedEntries
              .fold(0.0, (sum, entry) => sum + entry.value);
          final topCategory = cats.firstWhere(
            (c) => c.id == sortedEntries.first.key,
            orElse: () => cats.first,
          );

          final sections = sortedEntries.map((e) {
            final cat = cats.firstWhere(
              (c) => c.id == e.key,
              orElse: () => cats.first,
            );
            return PieChartSectionData(
              value: e.value,
              color: AppColors.fromHex(cat.color),
              title: '',
              radius: 36,
              showTitle: false,
            );
          }).toList();

          return GlowContainer(
            glowColor: AppColors.teal,
            glowRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.donut_large_outlined,
                        color: AppColors.teal,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category spending',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Top: ${topCategory.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.currencyCompact(total),
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 42,
                                sectionsSpace: 4,
                                startDegreeOffset: -90,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  Formatters.currencyCompact(total),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: sortedEntries.take(3).map((e) {
                            final cat = cats.firstWhere(
                              (c) => c.id == e.key,
                              orElse: () => cats.first,
                            );
                            final color = AppColors.fromHex(cat.color);
                            final pct = total == 0
                                ? 0.0
                                : (e.value / total)
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SpendingBreakdownRow(
                                name: cat.name,
                                amount: e.value,
                                percent: pct,
                                color: color,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (sortedEntries.length > 3) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '+${sortedEntries.length - 3} more categories',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: AppColors.bgSurface,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.insights_outlined,
                      color: AppColors.textHint,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${topCategory.name} has the largest share this month',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const _LoadingCard(height: 160),
        error: (e, _) => Text('$e'),
      ),
      loading: () => const _LoadingCard(height: 160),
      error: (e, _) => Text('$e'),
    );
  }
}

class _SpendingBreakdownRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percent;
  final Color color;

  const _SpendingBreakdownRow({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.currencyCompact(amount),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Goal card ──────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress =
        (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final color = AppColors.fromHex(goal.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.bgSurface, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(
                '${Formatters.currency(goal.currentAmount)} / ${Formatters.currency(goal.targetAmount)}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Formatters.percent(progress * 100)} complete',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Transaction tile ───────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionWithDetails item;
  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    final cat = item.category;
    final isIncome = t.type == 'income';
    final color = cat != null
        ? AppColors.fromHex(cat.color)
        : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.bgSurface, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(cat?.icon ?? ''),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.note ?? cat?.name ?? 'Transaction',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cat?.name ?? ''} • ${Formatters.relativeDate(t.date)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Formatters.currencyCompact(t.amount)}',
            style: TextStyle(
              color: isIncome
                  ? AppColors.income
                  : AppColors.expense,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String icon) {
    return switch (icon) {
      'food' => Icons.restaurant_outlined,
      'transport' => Icons.directions_car_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      'bills' => Icons.receipt_outlined,
      'health' => Icons.favorite_outline,
      'entertainment' => Icons.movie_outlined,
      'savings' => Icons.savings_outlined,
      'salary' => Icons.work_outline,
      'freelance' => Icons.laptop_outlined,
      'business' => Icons.business_center_outlined,
      'investment' => Icons.trending_up_outlined,
      'allowance' => Icons.wallet_outlined,
      'education' => Icons.school_outlined,
      _ => Icons.attach_money,
    };
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.bgSurface, width: 0.5),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.textHint, size: 32),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return _SkeletonPulse(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.bgSurface,
            width: 0.5,
          ),
        ),
        child: height <= 100
            ? const _SkeletonTile()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBlock(
                      width: 96, height: 12, radius: 6),
                  const SizedBox(height: 10),
                  const _SkeletonBlock(
                      width: 190, height: 26, radius: 8),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      children: const [
                        Expanded(
                          child: _SkeletonBlock(
                              height: double.infinity,
                              radius: 12),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _SkeletonBlock(
                              height: double.infinity,
                              radius: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonBlock(width: 42, height: 42, radius: 12),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 150, height: 12, radius: 6),
              SizedBox(height: 8),
              _SkeletonBlock(width: 92, height: 10, radius: 5),
            ],
          ),
        ),
        SizedBox(width: 12),
        _SkeletonBlock(width: 72, height: 14, radius: 7),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final Widget child;
  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}
