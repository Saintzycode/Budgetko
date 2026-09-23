import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';

Future<void> showTransactionSheet(
  BuildContext context,
  TransactionWithDetails item,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TransactionSheet(item: item),
  );
}

class _TransactionSheet extends ConsumerWidget {
  final TransactionWithDetails item;
  const _TransactionSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.transaction;
    final cat = item.category;
    final wallet = item.wallet;
    final isIncome = t.type == 'income';
    final color = cat != null
        ? AppColors.fromHex(cat.color)
        : AppColors.textSecondary;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIconData(cat?.icon ?? ''),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cat?.name ?? 'Transaction',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isIncome ? '+' : '-'}${Formatters.currency(t.amount)}',
                style: TextStyle(
                  color: isIncome
                      ? AppColors.income
                      : AppColors.expense,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.receipt_long_outlined,
                label: 'Note',
                value: t.note?.isNotEmpty == true
                    ? t.note!
                    : 'None',
              ),
              _DetailRow(
                icon: walletIconData(wallet?.type ?? ''),
                label: 'Wallet',
                value: wallet?.name ?? 'Unknown',
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: Formatters.dateFull(t.date),
              ),
              _DetailRow(
                icon: isIncome
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                label: 'Type',
                value: isIncome ? 'Income' : 'Expense',
                last: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await showTransactionEditor(
                              context, ref, t);
                        },
                        icon: const Icon(Icons.edit_outlined,
                            size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          side: const BorderSide(
                              color: AppColors.teal, width: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, ref),
                        icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.white),
                        label: const Text('Delete',
                            style: TextStyle(
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardLight,
        title: const Text('Delete transaction?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${Formatters.currency(item.transaction.amount)} will be removed permanently.',
          style:
              const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(transactionsDaoProvider)
        .deleteTransaction(item.transaction.id);
    invalidateTransactionAggregates(ref);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text('Transaction deleted',
            style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: AppColors.bgSurface),
      ],
    );
  }
}

// ── Editor ─────────────────────────────────────────────────────────────────────

Future<void> showTransactionEditor(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TransactionEditor(transaction: transaction),
  );
}

class _TransactionEditor extends ConsumerStatefulWidget {
  final Transaction transaction;
  const _TransactionEditor({required this.transaction});

  @override
  ConsumerState<_TransactionEditor> createState() =>
      _TransactionEditorState();
}

class _TransactionEditorState
    extends ConsumerState<_TransactionEditor> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  late int? _categoryId;
  late int? _walletId;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController = TextEditingController(
      text: t.amount % 1 == 0
          ? t.amount.toInt().toString()
          : t.amount.toString(),
    );
    _noteController = TextEditingController(text: t.note ?? '');
    _type = t.type;
    _categoryId = t.categoryId;
    _walletId = t.walletId;
    _date = t.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(
        _amountController.text
            .replaceAll(',', '')
            .trim(),
      ) ??
      0;
  bool get _canSave => _amount > 0 && _categoryId != null && _walletId != null && !_saving;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: now,
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final t = widget.transaction;
    final noteText = _noteController.text.trim();
    final date = DateTime(
      _date.year,
      _date.month,
      _date.day,
      t.date.hour,
      t.date.minute,
    );
    await ref.read(transactionsDaoProvider).updateTransaction(
          Transaction(
            id: t.id,
            amount: _amount,
            note: noteText.isEmpty ? null : noteText,
            categoryId: _categoryId!,
            walletId: _walletId!,
            type: _type,
            date: date,
            createdAt: t.createdAt,
          ),
        );
    invalidateTransactionAggregates(ref);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          'Updated ${Formatters.currency(_amount)}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(allWalletsProvider);
    final isIncome = _type == 'income';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius:
                          BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit transaction',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TypeToggle(
                        value: 'expense',
                        label: 'Expense',
                        current: _type,
                        onTap: () => setState(() {
                          _type = 'expense';
                          _categoryId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeToggle(
                        value: 'income',
                        label: 'Income',
                        current: _type,
                        onTap: () => setState(() {
                          _type = 'income';
                          _categoryId = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: TextStyle(
                      color: isIncome
                          ? AppColors.income
                          : AppColors.expense,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.bgSurface,
                          width: 0.5),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                catsAsync.when(
                  data: (cats) {
                    final filtered = cats
                        .where((c) => isIncome
                            ? c.isIncome
                            : !c.isIncome)
                        .toList();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filtered
                          .map((cat) {
                        final selected =
                            _categoryId == cat.id;
                        final color =
                            AppColors.fromHex(cat.color);
                        return GestureDetector(
                          onTap: () => setState(
                              () => _categoryId = cat.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(
                                      alpha: 0.2)
                                  : AppColors.bgSurface,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryIconData(
                                      cat.icon),
                                  size: 14,
                                  color: selected
                                      ? color
                                      : AppColors
                                          .textSecondary,
                                ),
                                const SizedBox(
                                    width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? color
                                        : AppColors
                                            .textSecondary,
                                    fontWeight:
                                        selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SpinKitRipple(
                      color: AppColors.teal, size: 24),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(
                          color:
                              AppColors.textSecondary)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Wallet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                walletsAsync.when(
                  data: (wallets) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wallets.map((w) {
                      final selected =
                          _walletId == w.id;
                      final color =
                          AppColors.fromHex(w.color);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _walletId = w.id),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(
                                    alpha: 0.2)
                                : AppColors.bgSurface,
                            borderRadius:
                                BorderRadius.circular(
                                    20),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                walletIconData(w.type),
                                size: 14,
                                color: selected
                                    ? color
                                    : AppColors
                                        .textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                w.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? color
                                      : AppColors
                                          .textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const SpinKitRipple(
                      color: AppColors.teal, size: 24),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(
                          color:
                              AppColors.textSecondary)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.bgSurface,
                                width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .calendar_today_outlined,
                                size: 16,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                Formatters.dateFull(_date),
                                style: const TextStyle(
                                    color: AppColors
                                        .textPrimary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLength: 200,
                  maxLengthEnforcement:
                      MaxLengthEnforcement.enforced,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Note (optional)',
                    hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    counterText: '',
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.bgSurface,
                          width: 0.5),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _canSave ? _save : null,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: _canSave
                          ? (isIncome
                              ? AppColors.income
                              : AppColors.expense)
                          : AppColors.bgSurface,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SpinKitRipple(
                            color: Colors.white,
                            size: 20)
                        : Text(
                            _categoryId == null
                                ? 'Select a category'
                                : !_canSave
                                    ? 'Enter an amount'
                                    : 'Save changes',
                            style: TextStyle(
                              color: _canSave
                                  ? Colors.white
                                  : AppColors
                                      .textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String value;
  final String label;
  final String current;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.value,
    required this.label,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final color = value == 'expense'
        ? AppColors.expense
        : AppColors.income;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppColors.textHint,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
