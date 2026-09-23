import 'dart:async';
import 'dart:io';

import '../../core/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../../../core/budget/budget_status.dart';
import '../transactions/transaction_sheet.dart';

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
                    color: AppColors.teal.withValues(alpha: 0.4),
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
        actions: const [
          _NotificationBell(),
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
            // ── Today ────────────────────────────────────────────
            const _TodayCard(),
            const SizedBox(height: 12),

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
            _SectionHeader(
              title: 'Spending breakdown',
              trailing: TextButton(
                onPressed: () => context.go('/alerts'),
                child: const Text('Limits',
                    style: TextStyle(
                        color: AppColors.teal, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            const _SpendingChart(),
            const SizedBox(height: 16),

            // ── Category budgets ───────────────────────────────────
            _SectionHeader(
              title: 'Category budgets',
              trailing: TextButton(
                onPressed: () => context.go('/alerts'),
                child: const Text('Manage',
                    style: TextStyle(
                        color: AppColors.teal, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            const _CategoryBudgets(),
            const SizedBox(height: 16),

            // ── Spending insights ────────────────────────────────
            const _SpendingInsightsCard(),
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
                      actionLabel: 'Create a goal',
                      onAction: () => context.go('/goals'),
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
                      actionLabel: 'Add transaction',
                      onAction: () =>
                          context.push('/quick-add'),
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
                      ? color.withValues(alpha: 0.2)
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 0.5),
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
              backgroundColor: color.withValues(alpha: 0.1),
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
              actionLabel: 'Add transaction',
              onAction: () => context.push('/quick-add'),
            );
          }

          final categoryById = {for (final c in cats) c.id: c};
          final knownEntries = spending.entries
              .where((e) => categoryById.containsKey(e.key))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (knownEntries.isEmpty) {
            return const _EmptyState(
              icon: Icons.pie_chart_outline,
              message: 'No spending data yet',
            );
          }

          final sortedEntries = knownEntries;
          Category categoryFor(int id) => categoryById[id]!;

          final total = sortedEntries
              .fold(0.0, (sum, entry) => sum + entry.value);
          final topCategory = categoryFor(sortedEntries.first.key);

          final sections = sortedEntries.map((e) {
            final cat = categoryFor(e.key);
            return PieChartSectionData(
              value: e.value,
              color: AppColors.fromHex(cat.color),
              title: '',
              radius: 36,
              showTitle: false,
            );
          }).toList();
          final visibleEntries = sortedEntries.take(3).toList();
          MapEntry<int, double>? limitAlertEntry;
          var limitAlertProgress = 0.0;
          for (final entry in sortedEntries) {
            final limit = categoryFor(entry.key).monthlyLimit;
            if (limit == null || limit <= 0) continue;
            final progress = entry.value / limit;
            if (progress >= 0.8 && progress > limitAlertProgress) {
              limitAlertEntry = entry;
              limitAlertProgress = progress;
            }
          }
          final insightText = limitAlertEntry == null
              ? '${topCategory.name} has the largest share this month'
              : limitAlertProgress > 1
                  ? '${categoryFor(limitAlertEntry.key).name} is over its monthly limit'
                  : '${categoryFor(limitAlertEntry.key).name} is near its monthly limit';

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
                        color: AppColors.teal.withValues(alpha: 0.14),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 150),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 42,
                                sectionsSpace: 4,
                                startDegreeOffset: -90,
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (event, response) {
                                    final index = response
                                        ?.touchedSection
                                        ?.touchedSectionIndex;
                                    if (index == null ||
                                        index < 0 ||
                                        index >=
                                            sortedEntries
                                                .length) {
                                      return;
                                    }
                                    _drillIntoCategory(context,
                                        ref,
                                        sortedEntries[index]
                                            .key);
                                  },
                                ),
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
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: visibleEntries.map((e) {
                            final cat = categoryFor(e.key);
                            final color = AppColors.fromHex(cat.color);
                            final pct = total == 0
                                ? 0.0
                                : (e.value / total)
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _SpendingBreakdownRow(
                                name: cat.name,
                                amount: e.value,
                                percent: pct,
                                color: color,
                                limit: cat.monthlyLimit,
                                onTap: () =>
                                    _drillIntoCategory(
                                        context, ref, cat.id),
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
                        insightText,
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

void _drillIntoCategory(
    BuildContext context, WidgetRef ref, int categoryId) {
  ref.read(transactionCategoryProvider.notifier).state = categoryId;
  ref.read(transactionSearchProvider.notifier).state = '';
  ref.read(transactionFilterProvider.notifier).state = 'all';
  context.go('/transactions');
}

// ── Spending insights ──────────────────────────────────────────────────────────

class _SpendingInsightsCard extends ConsumerWidget {
  const _SpendingInsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(spendingInsightsProvider);

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();
        final rows = <Widget>[];

        final mom = insights.monthOverMonthPercent;
        if (mom != null) {
          final down = mom <= 0;
          final magnitude = mom.abs();
          rows.add(_InsightRow(
            icon: down
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            color: down ? AppColors.income : AppColors.expense,
            text: down
                ? 'Spending ${magnitude.toStringAsFixed(0)}% lower than last month'
                : 'Spending ${magnitude.toStringAsFixed(0)}% higher than last month',
          ));
        } else if (insights.previousExpense == 0 &&
            insights.currentExpense > 0) {
          rows.add(const _InsightRow(
            icon: Icons.auto_graph,
            color: AppColors.teal,
            text: 'First month with recorded spending',
          ));
        }

        final weekend = insights.weekendPremiumPercent;
        if (weekend != null && weekend.abs() >= 5) {
          final up = weekend > 0;
          rows.add(_InsightRow(
            icon: Icons.weekend_outlined,
            color: up ? AppColors.warning : AppColors.teal,
            text: up
                ? 'You spend ${weekend.abs().toStringAsFixed(0)}% more per day on weekends'
                : 'You spend ${weekend.abs().toStringAsFixed(0)}% less per day on weekends',
          ));
        }

        final weekday = insights.topSpendWeekday;
        if (weekday != null) {
          rows.add(_InsightRow(
            icon: Icons.today_outlined,
            color: AppColors.teal,
            text:
                '${Formatters.weekdayName(weekday)}s are your biggest spending day',
          ));
        }

        for (final change in insights.topIncreases) {
          rows.add(_InsightRow(
            icon: Icons.north_east_rounded,
            color: AppColors.expense,
            text:
                '${change.name} up ${Formatters.currencyCompact(change.delta)} vs last month',
          ));
        }

        if (rows.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending insights',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GlowContainer(
              glowColor: AppColors.teal,
              glowRadius: 12,
              padding: const EdgeInsets.all(16),
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: rows,
              ),
            ),
          ],
        );
      },
      loading: () => const _LoadingCard(height: 140),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InsightRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category budgets ───────────────────────────────────────────────────────────

class _CategoryBudgets extends ConsumerWidget {
  const _CategoryBudgets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(categoryBudgetStatusProvider);

    return statusesAsync.when(
      data: (allEntries) {
        final entries = allEntries
            .where((e) => e.baseLimit > 0)
            .toList();
        if (entries.isEmpty) {
          return const _SetLimitPrompt();
        }

        final totalLimit =
            entries.fold(0.0, (s, e) => s + e.effectiveLimit);
        final totalSpent =
            entries.fold(0.0, (s, e) => s + e.spent);
        final totalRolled =
            entries.fold(0.0, (s, e) => s + e.rolledOver);
        final overCount =
            entries.where((e) => e.isOver).length;
        final totalProgress = totalLimit > 0
            ? (totalSpent / totalLimit).clamp(0.0, 1.0)
            : 0.0;
        final hasOverspend = overCount > 0;
        final isNear = !hasOverspend && totalProgress >= 0.8;
        final glow = hasOverspend
            ? AppColors.expense
            : isNear
                ? AppColors.warning
                : AppColors.teal;

          return GlowContainer(
            glowColor: glow,
            glowRadius: hasOverspend ? 24 : 12,
            padding: const EdgeInsets.all(16),
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasOverspend
                          ? '$overCount over budget'
                          : 'Monthly budget',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    if (totalRolled > 0)
                      Row(
                        children: [
                          const Icon(Icons.autorenew,
                              size: 12,
                              color: AppColors.teal),
                          const SizedBox(width: 4),
                          Text(
                            '+${Formatters.currencyCompact(totalRolled)} rolled over',
                            style: const TextStyle(
                                color: AppColors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.bgSurface,
                    valueColor:
                        AlwaysStoppedAnimation(glow),
                  ),
                ),
                const SizedBox(height: 14),
                ...entries.map((e) => _BudgetRow(
                      entry: e,
                      onTap: () => _drillIntoCategory(
                          context, ref, e.category.id),
                    )),
              ],
            ),
          );
      },
      loading: () => const _LoadingCard(height: 140),
      error: (e, _) => const SizedBox(),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final CategoryBudgetStatus entry;
  final VoidCallback onTap;
  const _BudgetRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final color = AppColors.fromHex(cat.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    _categoryIcon(cat.icon),
                    color: color,
                    size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (entry.hasRollover)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.autorenew,
                          size: 11, color: AppColors.teal),
                      const SizedBox(width: 2),
                      Text(
                        '+${Formatters.currencyCompact(entry.rolledOver)}',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              if (entry.isOver)
                const _StatusPill(
                    label: 'Over!',
                    color: AppColors.expense)
              else if (entry.isNear)
                _StatusPill(
                    label:
                        '${(entry.progress * 100).toStringAsFixed(0)}%',
                    color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                '${Formatters.currencyCompact(entry.spent)} / ${Formatters.currencyCompact(entry.effectiveLimit)}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.progress,
              minHeight: 5,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation(
                  entry.statusColor),
            ),
          ),
        ],
        ),
      ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SetLimitPrompt extends StatelessWidget {
  const _SetLimitPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppColors.bgSurface, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.tune,
              color: AppColors.textHint, size: 28),
          const SizedBox(height: 8),
          const Text(
            'No category budgets yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set monthly limits to stay on top of spending',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/alerts'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.tealFaded,
              foregroundColor: AppColors.tealLight,
            ),
            child: const Text('Set limits',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SpendingBreakdownRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percent;
  final Color color;
  final double? limit;
  final VoidCallback? onTap;

  const _SpendingBreakdownRow({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    this.limit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit != null && limit! > 0;
    final limitProgress =
        hasLimit ? (amount / limit!).clamp(0.0, 1.0).toDouble() : null;
    final isOverLimit = hasLimit && amount > limit!;
    final isNearLimit =
        hasLimit && !isOverLimit && limitProgress! >= 0.8;
    final statusColor = isOverLimit
        ? AppColors.expense
        : isNearLimit
            ? AppColors.warning
            : color;
    final amountLabel = hasLimit
        ? '${Formatters.currencyCompact(amount)} / ${Formatters.currencyCompact(limit!)}'
        : Formatters.currencyCompact(amount);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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
              amountLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: limitProgress ?? percent,
                  minHeight: 5,
                  backgroundColor: AppColors.bgSurface,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOverLimit
                  ? 'Over'
                  : isNearLimit
                      ? '${(limitProgress * 100).toStringAsFixed(0)}%'
                      : '${(percent * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
        ),
      ),
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
    final percent = (progress * 100).round();
    final remaining =
        (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
    final color = AppColors.fromHex(goal.color);
    final imagePath = goal.imagePath;
    final hasImage =
        imagePath != null && File(imagePath).existsSync();

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
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${Formatters.currencyCompact(goal.currentAmount)} / ${Formatters.currencyCompact(goal.targetAmount)}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent% complete',
                style: TextStyle(color: color, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${Formatters.currencyCompact(remaining)} to go',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
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

    return GestureDetector(
      onTap: () => showTransactionSheet(context, item),
      child: Container(
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
              color: color.withValues(alpha: 0.1),
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
      ),
    );
  }

}

// ── Today card ─────────────────────────────────────────────────────────────────

class _TodayCard extends StatefulWidget {
  const _TodayCard();

  @override
  State<_TodayCard> createState() => _TodayCardState();
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

class _TodayCardState extends State<_TodayCard> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.tealDark.withValues(alpha: 0.35),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealFaded, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today_outlined,
                color: AppColors.tealLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dayOfWeek(now),
                  style: const TextStyle(
                    color: AppColors.tealLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateFull(now),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.time(now),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return IconButton(
      onPressed: () => context.go('/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            size: 20,
            color: AppColors.textPrimary,
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(
                    minWidth: 14, minHeight: 14),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.expense,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add,
                    size: 17, color: Colors.white),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(
                      width: 96, height: 12, radius: 6),
                  SizedBox(height: 10),
                  _SkeletonBlock(
                      width: 190, height: 26, radius: 8),
                  SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      children: [
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
    return const Row(
      children: [
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
