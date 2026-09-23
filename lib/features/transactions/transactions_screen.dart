import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../../../core/widgets/month_picker.dart';
import 'transaction_sheet.dart';
import '../../core/router.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends ConsumerState<TransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(filteredTransactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final filter = ref.watch(transactionFilterProvider);
    final categoryId = ref.watch(transactionCategoryProvider);
    final catsAsync = ref.watch(categoriesProvider);
    Category? activeCategory;
    for (final c in catsAsync.valueOrNull ?? const <Category>[]) {
      if (c.id == categoryId) {
        activeCategory = c;
        break;
      }
    }

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
        title: Text(
          Formatters.month(month),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Month picker
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined,
                color: AppColors.teal),
            onPressed: () => _pickMonth(context, ref, month),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter tabs ────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: filter == 'all',
                  onTap: () =>
                      ref.read(transactionFilterProvider.notifier).state = 'all',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Income',
                  isSelected: filter == 'income',
                  color: AppColors.income,
                  onTap: () =>
                      ref.read(transactionFilterProvider.notifier).state = 'income',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expense',
                  isSelected: filter == 'expense',
                  color: AppColors.expense,
                  onTap: () =>
                      ref.read(transactionFilterProvider.notifier).state = 'expense',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Active category filter ────────────────────────────
          if (activeCategory != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.fromHex(activeCategory.color)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.fromHex(
                                activeCategory.color)
                            .withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIconData(
                              activeCategory.icon),
                          size: 13,
                          color: AppColors.fromHex(
                              activeCategory.color),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeCategory.name,
                          style: TextStyle(
                            color: AppColors.fromHex(
                                activeCategory.color),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(
                            transactionCategoryProvider.notifier)
                        .state = null,
                    icon: const Icon(Icons.close,
                        size: 14,
                        color: AppColors.textSecondary),
                    label: const Text('Clear',
                        style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Search bar ─────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: const TextStyle(
                    color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textHint, size: 18),
                isDense: true,
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.bgSurface,
                      width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.bgSurface,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.teal, width: 1),
                ),
              ),
              onChanged: (v) {
                  final sanitized = v.toLowerCase().replaceAll(
                      RegExp(r'[^a-z0-9\s]'), '');
                  ref.read(transactionSearchProvider.notifier).state = sanitized;
                },
            ),
          ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: txnsAsync.when(
              data: (txns) {
                if (txns.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                         Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.textHint,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                         Text(
                          'No transactions found',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                final grouped = <String,
                    List<TransactionWithDetails>>{};
                for (final t in txns) {
                  final key = Formatters.dateShort(
                      t.transaction.date);
                  grouped
                      .putIfAbsent(key, () => [])
                      .add(t);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 120),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, i) {
                    final date =
                        grouped.keys.elementAt(i);
                    final items = grouped[date]!;

                    // Calculate daily total
                    double dayTotal = 0;
                    for (final t in items) {
                      if (t.transaction.type == 'income') {
                        dayTotal += t.transaction.amount;
                      } else {
                        dayTotal -= t.transaction.amount;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...items.map((t) => _TransactionCard(item: t)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Daily: ${Formatters.currency(dayTotal)}',
                              style: TextStyle(
                                color: dayTotal >= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SpinKitRipple(
                    color: AppColors.teal, size: 42),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final picked =
        await showMonthPicker(context, initial: current);
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).setMonth(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color?.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.teal)
                : AppColors.bgSurface,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? (color ?? AppColors.teal) : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Transaction card ───────────────────────────────────────────────────────────

class _TransactionCard extends ConsumerWidget {
  final TransactionWithDetails item;
  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.transaction;
    final cat = item.category;
    final wallet = item.wallet;
    final isIncome = t.type == 'income';
    final color = cat != null
        ? AppColors.fromHex(cat.color)
        : AppColors.textSecondary;

    return Dismissible(
      key: Key('txn-${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.expense.withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: const Text('Delete transaction?',
                style:
                    TextStyle(color: AppColors.textPrimary)),
            content: const Text('This cannot be undone.',
                style: TextStyle(
                    color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(
                        color: AppColors.expense)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(transactionsDaoProvider)
            .deleteTransaction(t.id);
        invalidateTransactionAggregates(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.bgCard,
            content: Text('Transaction deleted',
                style:
                    TextStyle(color: AppColors.textPrimary)),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => showTransactionSheet(context, item),
        child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.bgSurface, width: 0.5),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(cat?.icon ?? ''),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    t.note ?? cat?.name ?? 'Transaction',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        cat?.name ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (wallet != null) ...[
                        const Text(' • ',
                            style: TextStyle(
                                color:
                                    AppColors.textHint,
                                fontSize: 12)),
                        Icon(
                          _walletIcon(wallet.type),
                          size: 11,
                          color: AppColors.fromHex(
                              wallet.color),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          wallet.name,
                          style: TextStyle(
                            color: AppColors.fromHex(
                                wallet.color),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                Text(
                  Formatters.time(t.date),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  IconData _walletIcon(String type) {
    return switch (type) {
      'cash' => Icons.payments_outlined,
      'gcash' => Icons.phone_android_outlined,
      'bank' => Icons.account_balance_outlined,
      _ => Icons.wallet_outlined,
    };
  }
}
