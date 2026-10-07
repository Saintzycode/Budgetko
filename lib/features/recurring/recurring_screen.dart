import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/category_icons.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(allRecurringProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Recurring',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.teal),
            onPressed: () =>
                _showAddSheet(context, ref),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat,
                      size: 64,
                      color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    'No recurring transactions',
                    style: TextStyle(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _showAddSheet(context, ref),
                    child: const Text('Add recurring'),
                  ),
                ],
              ),
            );
          }

          final active = items
              .where((i) => i.recurring.isActive)
              .toList();
          final paused = items
              .where((i) => !i.recurring.isActive)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 120),
            children: [
              if (active.isNotEmpty) ...[
                _RecurringSummary(items: active),
                const SizedBox(height: 20),
                const Text('Active',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                ...active.map(
                    (i) => _RecurringCard(item: i)),
              ],
              if (paused.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Paused',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                ...paused.map(
                    (i) => _RecurringCard(item: i)),
              ],
            ],
          );
        },
        loading: () => const Center(
            child: SpinKitRipple(
                color: AppColors.teal, size: 42)),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

// ── Monthly summary ─────────────────────────────────────────────────────────────

/// Projects active recurring items onto a monthly figure so the user can
/// see the committed cost of their subscriptions at a glance.
class _RecurringSummary extends StatelessWidget {
  final List<RecurringWithDetails> items;
  const _RecurringSummary({required this.items});

  double _monthlyEquivalent(RecurringTransaction r) {
    return switch (r.frequency) {
      'daily' => r.amount * 30,
      'weekly' => r.amount * 4.33,
      'monthly' => r.amount,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expense = 0.0;
    for (final item in items) {
      final r = item.recurring;
      if (!r.isActive) continue;
      final monthly = _monthlyEquivalent(r);
      if (r.type == 'income') {
        income += monthly;
      } else {
        expense += monthly;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.bgSurface, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryBlock(
              label: 'Monthly in',
              value: Formatters.currencyCompact(income),
              color: AppColors.income,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: AppColors.bgSurface,
          ),
          Expanded(
            child: _SummaryBlock(
              label: 'Monthly out',
              value: Formatters.currencyCompact(expense),
              color: AppColors.expense,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: AppColors.bgSurface,
          ),
          Expanded(
            child: _SummaryBlock(
              label: 'Left over',
              value: Formatters.currencyCompact(income - expense),
              color: income - expense >= 0
                  ? AppColors.teal
                  : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
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

// ── Recurring card ─────────────────────────────────────────────────────────────

class _RecurringCard extends ConsumerWidget {
  final RecurringWithDetails item;
  const _RecurringCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = item.recurring;
    final cat = item.category;
    final wallet = item.wallet;
    final isIncome = r.type == 'income';
    final color = cat != null
        ? AppColors.fromHex(cat.color)
        : AppColors.textSecondary;
    final active = r.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.30)
              : AppColors.bgSurface,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              categoryIconData(cat?.icon ?? ''),
              color: active ? color : AppColors.textHint,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.note ?? cat?.name ?? 'Recurring',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _frequencyLabel(r),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (wallet != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        _walletIcon(wallet.type),
                        size: 11,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _DueChip(recurring: r),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${Formatters.currency(r.amount)}',
                style: TextStyle(
                  color: active
                      ? (isIncome
                          ? AppColors.income
                          : AppColors.expense)
                      : AppColors.textHint,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RoundAction(
                    icon: active
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: active
                        ? AppColors.textSecondary
                        : AppColors.teal,
                    tooltip: active ? 'Pause' : 'Resume',
                    onTap: () => ref
                        .read(recurringDaoProvider)
                        .updateRecurring(
                            r.copyWith(isActive: !active)),
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    icon: Icons.delete_outline,
                    color: AppColors.textHint,
                    tooltip: 'Delete',
                    onTap: () => _confirmDelete(context, ref, r.id),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _frequencyLabel(RecurringTransaction r) {
    return switch (r.frequency) {
      'daily' => 'Daily',
      'weekly' =>
        'Every ${Formatters.weekdayName(r.dayOfWeek ?? 1)}',
      'monthly' =>
        'Every ${Formatters.ordinal(r.dayOfMonth ?? 1)}',
      _ => r.frequency,
    };
  }

  IconData _walletIcon(String type) {
    return switch (type) {
      'cash' => Icons.payments_outlined,
      'ewallet' => Icons.account_balance_wallet_outlined,
      'gcash' => Icons.phone_android_outlined,
      'bank' => Icons.account_balance_outlined,
      _ => Icons.wallet_outlined,
    };
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete recurring?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(recurringDaoProvider)
                  .deleteRecurring(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  final RecurringTransaction recurring;
  const _DueChip({required this.recurring});

  @override
  Widget build(BuildContext context) {
    if (!recurring.isActive) {
      return const _Chip(
        icon: Icons.pause_rounded,
        label: 'Paused',
        color: AppColors.textHint,
        background: AppColors.bgSurface,
      );
    }

    final next = _RecurringNextRun.of(recurring);
    if (next == null) {
      return const _Chip(
        icon: Icons.repeat,
        label: 'Scheduled',
        color: AppColors.textSecondary,
        background: AppColors.bgSurface,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = next.difference(today).inDays;

    if (days <= 1) {
      return _Chip(
        icon: Icons.schedule,
        label: days <= 0 ? 'Due today' : 'Due tomorrow',
        color: AppColors.warning,
        background: AppColors.warning.withValues(alpha: 0.14),
      );
    }
    if (days <= 7) {
      return _Chip(
        icon: Icons.schedule,
        label: 'In $days days',
        color: AppColors.teal,
        background: AppColors.teal.withValues(alpha: 0.14),
      );
    }
    return _Chip(
      icon: Icons.event_outlined,
      label: 'On ${Formatters.dateShort(next)}',
      color: AppColors.textSecondary,
      background: AppColors.bgSurface,
    );
  }

}

class _RecurringNextRun {
  /// The next date a recurring item is due, or null for an unknown
  /// frequency. Advances from the last run (or start date), never before
  /// today.
  static DateTime? of(RecurringTransaction r) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start =
        DateTime(r.startDate.year, r.startDate.month, r.startDate.day);

    var earliest = start;
    if (r.lastRunAt != null) {
      final last = r.lastRunAt!;
      earliest = DateTime(last.year, last.month, last.day)
          .add(const Duration(days: 1));
    }
    if (earliest.isBefore(today)) earliest = today;

    switch (r.frequency) {
      case 'daily':
        return earliest;
      case 'weekly':
        final target = r.dayOfWeek ?? start.weekday;
        return earliest
            .add(Duration(days: (target - earliest.weekday) % 7));
      case 'monthly':
        final target = r.dayOfMonth ?? start.day;
        // Clamp so a 31st does not roll into a following shorter month.
        final daysInMonth =
            DateTime(earliest.year, earliest.month + 1, 0).day;
        final day = target > daysInMonth ? daysInMonth : target;
        var cursor = DateTime(earliest.year, earliest.month, day);
        if (cursor.isBefore(earliest)) {
          cursor =
              DateTime(earliest.year, earliest.month + 1, day);
        }
        return cursor;
      default:
        return null;
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add recurring sheet ────────────────────────────────────────────────────────

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() =>
      _AddRecurringSheetState();
}

class _AddRecurringSheetState
    extends ConsumerState<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  String _frequency = 'monthly';
  Category? _selectedCategory;
  Wallet? _selectedWallet;
  int _dayOfWeek = 1;
  int _dayOfMonth = 1;

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(allWalletsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('New recurring transaction',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 16),

              // Type toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: ['expense', 'income'].map((t) {
                    final isSelected = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          _selectedCategory = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (t == 'income'
                                    ? AppColors.income
                                    : AppColors.expense)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Text(
                            t == 'income'
                                ? 'Income'
                                : 'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountController,
                style: const TextStyle(
                    color: AppColors.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Enter an amount';
                  }
                  final parsed = double.tryParse(v);
                  if (parsed == null) {
                    return 'Invalid number';
                  }
                  if (parsed <= 0) {
                    return 'Amount must be above 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category
              categoriesAsync.when(
                data: (cats) {
                  final filtered = cats
                      .where((c) => _type == 'income'
                          ? c.isIncome
                          : !c.isIncome)
                      .toList();
                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    dropdownColor: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.expand_more,
                        color: AppColors.textSecondary),
                    isExpanded: true,
                    style: const TextStyle(
                        color: AppColors.textPrimary),
                    decoration: _dropdownDecoration(
                      label: 'Category',
                      icon: Icons.category_outlined,
                    ),
                    selectedItemBuilder: (_) => filtered
                        .map((c) => _categoryOption(c,
                            compact: true))
                        .toList(),
                    items: filtered
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: _categoryOption(c),
                            ))
                        .toList(),
                    onChanged: (c) => setState(
                        () => _selectedCategory = c),
                    validator: (v) => v == null
                        ? 'Select a category'
                        : null,
                  );
                },
                loading: () => const SizedBox(
                    height: 60,
                    child: Center(
                        child: SpinKitRipple(
                            color: AppColors.teal, size: 28))),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),

              // Wallet
              walletsAsync.when(
                data: (wallets) =>
                    DropdownButtonFormField<Wallet>(
                  initialValue: _selectedWallet,
                  dropdownColor: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.expand_more,
                      color: AppColors.textSecondary),
                  isExpanded: true,
                  style: const TextStyle(
                      color: AppColors.textPrimary),
                  decoration: _dropdownDecoration(
                    label: 'Wallet',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  selectedItemBuilder: (_) => wallets
                      .map((w) => _walletOption(w,
                          compact: true))
                      .toList(),
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: _walletOption(w),
                          ))
                      .toList(),
                  onChanged: (w) =>
                      setState(() => _selectedWallet = w),
                  validator: (v) => v == null
                      ? 'Select a wallet'
                      : null,
                ),
                loading: () => const SizedBox(
                    height: 60,
                    child: Center(
                        child: SpinKitRipple(
                            color: AppColors.teal, size: 28))),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteController,
                style: const TextStyle(
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Netflix subscription',
                ),
              ),
              const SizedBox(height: 12),

              // Frequency
              const Text('Repeat',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: ['daily', 'weekly', 'monthly']
                    .map((f) {
                  final isSelected = _frequency == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _frequency = f),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.teal
                              : AppColors.bgSurface,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          f[0].toUpperCase() +
                              f.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Weekly day picker
              if (_frequency == 'weekly') ...[
                DropdownButtonFormField<int>(
                  initialValue: _dayOfWeek,
                  dropdownColor: AppColors.bgCard,
                  style: const TextStyle(
                      color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Every'),
                  items: List.generate(7, (i) => i + 1)
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(_weekdays[d - 1]),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _dayOfWeek = v ?? 1),
                ),
                const SizedBox(height: 12),
              ],

              // Monthly day picker
              if (_frequency == 'monthly') ...[
                DropdownButtonFormField<int>(
                  initialValue: _dayOfMonth,
                  dropdownColor: AppColors.bgCard,
                  style: const TextStyle(
                      color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Every month on day'),
                  items: List.generate(28, (i) => i + 1)
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('Day $d'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _dayOfMonth = v ?? 1),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text(
                      'Save recurring transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recurringDaoProvider).insertRecurring(
          RecurringTransactionsCompanion.insert(
            amount: double.parse(_amountController.text),
            categoryId: _selectedCategory!.id,
            walletId: _selectedWallet!.id,
            type: _type,
            frequency: _frequency,
            startDate: DateTime.now(),
            note: Value(_noteController.text.isEmpty
                ? null
                : _noteController.text),
            dayOfWeek:
                Value(_frequency == 'weekly' ? _dayOfWeek : null),
            dayOfMonth:
                Value(_frequency == 'monthly' ? _dayOfMonth : null),
          ),
        );
    if (!mounted) return;
    final createdCount =
        await ref.read(databaseProvider).processDueRecurring();
    if (!mounted) return;
    ref
      ..invalidate(allTransactionsProvider)
      ..invalidate(transactionsForMonthProvider)
      ..invalidate(monthlyTotalsProvider)
      ..invalidate(spendingByCategoryProvider)
      ..invalidate(last6MonthsProvider)
      ..invalidate(allRecurringProvider)
      ..invalidate(spendingInsightsProvider)
      ..invalidate(categoryBudgetStatusProvider);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          content: Text(
            createdCount == 0
                ? 'Recurring transaction saved'
                : createdCount == 1
                    ? 'Recurring transaction added'
                    : '$createdCount recurring transactions added',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.textSecondary,
        size: 18,
      ),
      filled: true,
      fillColor: AppColors.bgSurface,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.bgSurface,
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.bgSurface,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.teal,
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.expense,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.expense,
          width: 1,
        ),
      ),
    );
  }

  Widget _categoryOption(Category category, {bool compact = false}) {
    final color = AppColors.fromHex(category.color);
    return Row(
      children: [
        Container(
          width: compact ? 26 : 32,
          height: compact ? 26 : 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _categoryIcon(category.icon),
            color: color,
            size: compact ? 14 : 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _walletOption(Wallet wallet, {bool compact = false}) {
    final color = AppColors.fromHex(wallet.color);
    return Row(
      children: [
        Container(
          width: compact ? 26 : 32,
          height: compact ? 26 : 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _walletIcon(wallet.type),
            color: color,
            size: compact ? 14 : 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            wallet.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String icon) => categoryIconData(icon);

  IconData _walletIcon(String type) {
    return switch (type) {
      'cash' => Icons.payments_outlined,
      'ewallet' => Icons.account_balance_wallet_outlined,
      'gcash' => Icons.phone_android_outlined,
      'bank' => Icons.account_balance_outlined,
      _ => Icons.wallet_outlined,
    };
  }
}
