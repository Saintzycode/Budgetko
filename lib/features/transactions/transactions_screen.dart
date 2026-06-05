import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../core/router.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends ConsumerState<TransactionsScreen> {
  String _search = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(transactionsForMonthProvider);
    final month = ref.watch(selectedMonthProvider);

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
                  isSelected: _filter == 'all',
                  onTap: () =>
                      setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Income',
                  isSelected: _filter == 'income',
                  color: AppColors.income,
                  onTap: () =>
                      setState(() => _filter = 'income'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expense',
                  isSelected: _filter == 'expense',
                  color: AppColors.expense,
                  onTap: () =>
                      setState(() => _filter = 'expense'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

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
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
            ),
          ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: txnsAsync.when(
              data: (txns) {
                final filtered = txns.where((t) {
                  if (_filter != 'all' &&
                      t.transaction.type != _filter) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final note = (t.transaction.note ?? '')
                        .toLowerCase();
                    final cat =
                        (t.category?.name ?? '').toLowerCase();
                    if (!note.contains(_search) &&
                        !cat.contains(_search)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
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
                for (final t in filtered) {
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                dayTotal >= 0
                                    ? '+${Formatters.currencyCompact(dayTotal)}'
                                    : Formatters.currencyCompact(
                                        dayTotal.abs()),
                                style: TextStyle(
                                  color: dayTotal >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map(
                          (t) => _TransactionCard(item: t),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.teal),
              ),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
            ),
          ),
        ],
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
      ref.read(selectedMonthProvider.notifier).setMonth(picked);
    }
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color = AppColors.teal,
    required this.onTap,
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
              ? color.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.bgSurface,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? color : AppColors.textSecondary,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.bgCard,
            content: Text('Transaction deleted',
                style:
                    TextStyle(color: AppColors.textPrimary)),
          ),
        );
      },
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
