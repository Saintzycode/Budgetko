import '../../core/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final spendingAsync = ref.watch(spendingByCategoryProvider);

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
          'Spending Limits',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenseCats =
              categories.where((c) => !c.isIncome).toList();
          return spendingAsync.when(
            data: (spending) => ListView(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 120),
              children: [
                // ── Info banner ──────────────────────────
                const GlowContainer(
                  glowColor: AppColors.teal,
                  glowRadius: 10,
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.teal, size: 18),
                       SizedBox(width: 10),
                       Expanded(
                        child: Text(
                          'Set monthly limits per category. You\'ll be warned at 80% and 100%.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'This month',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Category cards ───────────────────────
                ...expenseCats.map((cat) {
                  final spent = spending[cat.id] ?? 0.0;
                  final limit = cat.monthlyLimit;
                  final progress = limit != null && limit > 0
                      ? (spent / limit).clamp(0.0, 1.0)
                      : null;
                  final isOver =
                      limit != null && spent > limit;
                  final isWarning = progress != null &&
                      progress >= 0.8 &&
                      !isOver;
                  final color = AppColors.fromHex(cat.color);
                  final statusColor = isOver
                      ? AppColors.expense
                      : isWarning
                          ? AppColors.warning
                          : AppColors.teal;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlowContainer(
                      glowColor: limit != null
                          ? statusColor
                          : AppColors.bgSurface,
                      glowRadius: 8,
                      padding: const EdgeInsets.all(14),
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    color.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              child: Icon(
                                _categoryIcon(cat.icon),
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(
                                  color:
                                      AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Status badge
                            if (isOver)
                              const _StatusBadge(
                                  label: 'Over!',
                                  color: AppColors.expense)
                            else if (isWarning)
                             const _StatusBadge(
                                  label: '80%',
                                  color: AppColors.warning),
                            const SizedBox(width: 8),
                            // Edit button
                            GestureDetector(
                              onTap: () =>
                                  _showLimitDialog(
                                      context,
                                      ref,
                                      cat.id,
                                      cat.name,
                                      cat.monthlyLimit),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius:
                                      BorderRadius.circular(
                                          10),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color:
                                      AppColors.textSecondary,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (limit != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: statusColor
                                  .withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation(
                                      statusColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                'Spent: ${Formatters.currency(spent)}',
                                style: const TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Limit: ${Formatters.currency(limit)}',
                                style: const TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                'Spent: ${Formatters.currency(spent)}',
                                style: const TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showLimitDialog(
                                    context,
                                    ref,
                                    cat.id,
                                    cat.name,
                                    null),
                                child: const Text(
                                  '+ Set limit',
                                  style: TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.teal)),
            error: (e, _) =>
                Center(child: Text('$e')),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.teal)),
        error: (e, _) =>
            Center(child: Text('$e')),
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
      'education' => Icons.school_outlined,
      _ => Icons.category_outlined,
    };
  }

  void _showLimitDialog(
    BuildContext context,
    WidgetRef ref,
    int catId,
    String catName,
    double? currentLimit,
  ) {
    final controller = TextEditingController(
      text: currentLimit?.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Set limit for $catName',
          style: const TextStyle(
              color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
          style: const TextStyle(
              color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Monthly limit',
            prefixText: '₱ ',
          ),
          autofocus: true,
        ),
        actions: [
          if (currentLimit != null)
            TextButton(
              onPressed: () {
                ref
                    .read(categoriesDaoProvider)
                    .updateMonthlyLimit(catId, null);
                Navigator.pop(ctx);
              },
              child: const Text('Remove',
                  style: TextStyle(
                      color: AppColors.expense)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(categoriesDaoProvider)
                    .updateMonthlyLimit(catId, amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(
      {required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
