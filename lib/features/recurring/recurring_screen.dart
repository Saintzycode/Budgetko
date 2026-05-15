import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../core/router.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(allRecurringProvider);

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
            child: CircularProgressIndicator(
                color: AppColors.teal)),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
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

    return GlowContainer(
      glowColor:
          r.isActive ? color : AppColors.bgSurface,
      glowRadius: 8,
      padding: const EdgeInsets.all(14),
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(
                  r.isActive ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.repeat,
              color: r.isActive
                  ? color
                  : AppColors.textHint,
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
                  r.note ?? cat?.name ?? 'Recurring',
                  style: TextStyle(
                    color: r.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat?.name ?? ''} • ${_frequencyLabel(r)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (wallet != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _walletIcon(wallet.type),
                        size: 11,
                        color: AppColors.fromHex(
                            wallet.color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wallet.name,
                        style: TextStyle(
                          color: AppColors.fromHex(
                              wallet.color),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Amount + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${Formatters.currencyCompact(r.amount)}',
                style: TextStyle(
                  color: isIncome
                      ? AppColors.income
                      : AppColors.expense,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Pause/Resume toggle
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(recurringDaoProvider)
                          .updateRecurring(r.copyWith(
                              isActive: !r.isActive));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: r.isActive
                            ? AppColors.teal
                                .withOpacity(0.15)
                            : AppColors.bgSurface,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          color: r.isActive
                              ? AppColors.teal
                              : AppColors.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete
                  GestureDetector(
                    onTap: () =>
                        _confirmDelete(context, ref, r.id),
                    child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.textHint),
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
      'daily' => 'Every day',
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
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(recurringDaoProvider)
                  .deleteRecurring(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style:
                    TextStyle(color: AppColors.expense)),
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
                  if (double.tryParse(v) == null) {
                    return 'Invalid number';
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
                    value: _selectedCategory,
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Category'),
                    items: filtered
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor:
                                        AppColors.fromHex(
                                            c.color),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (c) => setState(
                        () => _selectedCategory = c),
                    validator: (v) => v == null
                        ? 'Select a category'
                        : null,
                  );
                },
                loading: () =>
                    const LinearProgressIndicator(
                        color: AppColors.teal),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),

              // Wallet
              walletsAsync.when(
                data: (wallets) =>
                    DropdownButtonFormField<Wallet>(
                  value: _selectedWallet,
                  dropdownColor: AppColors.bgCard,
                  style: const TextStyle(
                      color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Wallet'),
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Row(
                              children: [
                                Icon(
                                  _walletIcon(w.type),
                                  size: 16,
                                  color: AppColors.fromHex(
                                      w.color),
                                ),
                                const SizedBox(width: 8),
                                Text(w.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (w) =>
                      setState(() => _selectedWallet = w),
                  validator: (v) => v == null
                      ? 'Select a wallet'
                      : null,
                ),
                loading: () =>
                    const LinearProgressIndicator(
                        color: AppColors.teal),
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
                  value: _dayOfWeek,
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
                  value: _dayOfMonth,
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
            dayOfWeek: Value(
                _frequency == 'weekly' ? _dayOfWeek : null),
            dayOfMonth: Value(_frequency == 'monthly'
                ? _dayOfMonth
                : null),
          ),
        );
    if (mounted) Navigator.pop(context);
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