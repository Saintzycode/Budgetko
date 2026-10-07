import 'package:budgetko/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // last6MonthsProvider returns oldest -> newest, so the last index is
  // the current month. The overview shows a single month at a time and
  // lets the user step back through history.
  int _monthIndex = 5;

  @override
  Widget build(BuildContext context) {
    final last6Async = ref.watch(last6MonthsProvider);
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
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

          // ── Month overview (single month, navigable) ───
          const Text(
            'Monthly Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          last6Async.when(
            data: (months) {
              // Guard against a shorter list if the provider changes.
              final index = _monthIndex.clamp(0, months.length - 1);
              return _MonthBarChart(
                months: months,
                index: index,
                onIndexChanged: (i) =>
                    setState(() => _monthIndex = i),
              );
            },
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

class _MonthBarChart extends StatelessWidget {
  final List<MonthlyTotals> months;
  final int index;
  final ValueChanged<int> onIndexChanged;
  const _MonthBarChart({
    required this.months,
    required this.index,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const GlowContainer(
        glowColor: AppColors.bgSurface,
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No overview data yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final totals = months[index];
    final now = DateTime.now();
    final date = DateTime(now.year, now.month - ((months.length - 1) - index));
    final maxValue = [totals.income, totals.expense].reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

    return GlowContainer(
      glowColor: AppColors.teal,
      glowRadius: 15,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrow(
                icon: Icons.chevron_left,
                enabled: index > 0,
                onTap: () => onIndexChanged(index - 1),
              ),
              Text(
                Formatters.monthShort(date),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _NavArrow(
                icon: Icons.chevron_right,
                enabled: index < months.length - 1,
                onTap: () => onIndexChanged(index + 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totals.income,
                        color: AppColors.income,
                        width: 26,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totals.expense,
                        color: AppColors.expense,
                        width: 26,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.bgCard,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        Formatters.currencyCompact(rod.toY),
                        TextStyle(
                          color: rod.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final label = value.toInt() == 0 ? 'Income' : 'Expenses';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.bgSurface,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MonthStat(
                label: 'Income',
                value: Formatters.currencyCompact(totals.income),
                color: AppColors.income,
              ),
              _MonthStat(
                label: 'Expenses',
                value: Formatters.currencyCompact(totals.expense),
                color: AppColors.expense,
              ),
              _MonthStat(
                label: 'Saved',
                value: Formatters.currencyCompact(totals.savings),
                color: totals.savings >= 0
                    ? AppColors.teal
                    : AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.bgSurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textHint.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
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
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
                        color.withValues(alpha: 0.1),
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
        child: SpinKitRipple(
          color: AppColors.teal,
          size: 30,
        ),
      ),
    );
  }
}
