import 'package:budgetko/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../core/router.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last6Async = ref.watch(last6MonthsProvider);
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);

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
          'Reports',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── This month summary ─────────────────────────────
          totalsAsync.when(
            data: (totals) => _MonthSummary(totals: totals),
            loading: () =>
                const _LoadingCard(height: 100),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),

          // ── 6 month bar chart ──────────────────────────────
          const Text(
            '6-Month Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          last6Async.when(
            data: (months) => _BarChart(months: months),
            loading: () =>
                const _LoadingCard(height: 220),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),

          // ── Spending by category ───────────────────────────
          const Text(
            'Spending by Category',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          spendingAsync.when(
            data: (spending) => categoriesAsync.when(
              data: (cats) => _CategoryBreakdown(
                spending: spending,
                categories: cats,
              ),
              loading: () =>
                  const _LoadingCard(height: 200),
              error: (e, _) => Text('$e'),
            ),
            loading: () =>
                const _LoadingCard(height: 200),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

// ── Month summary ──────────────────────────────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final MonthlyTotals totals;
  const _MonthSummary({required this.totals});

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      glowColor: AppColors.teal,
      glowRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Income',
              value: Formatters.currencyCompact(
                  totals.income),
              color: AppColors.income,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
              width: 0.5,
              height: 40,
              color: AppColors.bgSurface),
          Expanded(
            child: _StatItem(
              label: 'Expenses',
              value: Formatters.currencyCompact(
                  totals.expense),
              color: AppColors.expense,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
              width: 0.5,
              height: 40,
              color: AppColors.bgSurface),
          Expanded(
            child: _StatItem(
              label: 'Saved',
              value: Formatters.currencyCompact(
                  totals.savings),
              color: AppColors.savings,
              icon: Icons.savings_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── 6 month bar chart ──────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<MonthlyTotals> months;
  const _BarChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return GlowContainer(
      glowColor: AppColors.teal,
      glowRadius: 15,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: months.fold(
                      0.0,
                      (max, m) => m.income > max
                          ? m.income
                          : max,
                    ) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex,
                        rod, rodIndex) {
                      return BarTooltipItem(
                        Formatters.currencyCompact(
                            rod.toY),
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final monthIndex =
                            value.toInt();
                        final date = DateTime(
                          now.year,
                          now.month - (5 - monthIndex),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(
                              top: 6),
                          child: Text(
                            Formatters.monthShort(date)
                                .split(' ')[0],
                            style: const TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const   FlLine(
                    color: AppColors.bgSurface,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  months.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].income,
                        color: AppColors.income
                            .withOpacity(0.8),
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: months[i].expense,
                        color: AppColors.expense
                            .withOpacity(0.8),
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: AppColors.income,
                  label: 'Income'),
               SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.expense,
                  label: 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(
      {required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Category breakdown ─────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final Map<int, double> spending;
  final List<Category> categories;

  const _CategoryBreakdown({
    required this.spending,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (spending.isEmpty) {
      return const GlowContainer(
        glowColor: AppColors.bgSurface,
        padding:  EdgeInsets.all(24),
        child:  Center(
          child: Text(
            'No spending data this month',
            style: TextStyle(
                color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final total =
        spending.values.fold(0.0, (sum, v) => sum + v);

    // Sort by amount descending
    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlowContainer(
      glowColor: AppColors.teal,
      glowRadius: 15,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sorted.map((e) {
          final cat = categories.firstWhere(
            (c) => c.id == e.key,
            orElse: () => categories.first,
          );
          final color = AppColors.fromHex(cat.color);
          final pct = e.value / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.currency(e.value),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.percent(pct * 100),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor:
                        color.withOpacity(0.1),
                    valueColor:
                        AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.teal,
          strokeWidth: 2,
        ),
      ),
    );
  }
}