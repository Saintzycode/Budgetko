import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() =>
      _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  String _type = 'expense';
  String _input = '';
  Category? _selectedCategory;
  Wallet? _selectedWallet;
  bool _saving = false;

  double get _amount => double.tryParse(_input) ?? 0;
  bool get _canSave =>
      _amount > 0 &&
      _selectedCategory != null &&
      _selectedWallet != null &&
      !_saving;

  void _onNumpad(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '.') {
        if (!_input.contains('.')) {
          _input = _input.isEmpty ? '0.' : '$_input.';
        }
      } else {
        if (_input == '0') {
          _input = value;
        } else {
          _input += value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(allWalletsProvider);

    // Auto select first wallet
    walletsAsync.whenData((wallets) {
      if (_selectedWallet == null && wallets.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _selectedWallet = wallets.first);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Quick Add',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // ── Type toggle ────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() {
                      _type = _type == 'expense'
                          ? 'income'
                          : 'expense';
                      _selectedCategory = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _type == 'expense'
                            ? AppColors.expense
                                .withValues(alpha: 0.15)
                            : AppColors.income
                                .withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: _type == 'expense'
                              ? AppColors.expense
                                  .withValues(alpha: 0.4)
                              : AppColors.income
                                  .withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _type == 'expense'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: _type == 'expense'
                                ? AppColors.expense
                                : AppColors.income,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _type == 'expense'
                                ? 'Expense'
                                : 'Income',
                            style: TextStyle(
                              color: _type == 'expense'
                                  ? AppColors.expense
                                  : AppColors.income,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Amount display ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 20, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _input.isEmpty ? '₱ 0' : '₱ $_input',
                    style: TextStyle(
                      color: _type == 'expense'
                          ? AppColors.expense
                          : AppColors.income,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  // Wallet selector
                  walletsAsync.when(
                    data: (wallets) => SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: wallets.map((w) {
                          final isSelected =
                              _selectedWallet?.id == w.id;
                          final color =
                              AppColors.fromHex(w.color);
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedWallet = w),
                            child: AnimatedContainer(
                              duration: const Duration(
                                  milliseconds: 150),
                              margin: const EdgeInsets.only(
                                  right: 8),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.2)
                                    : AppColors.bgCard,
                                borderRadius:
                                    BorderRadius.circular(16),
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
                                    size: 12,
                                    color: isSelected
                                        ? color
                                        : AppColors
                                            .textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    w.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? color
                                          : AppColors
                                              .textSecondary,
                                      fontSize: 12,
                                      fontWeight: isSelected
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
                    ),
                    loading: () => const SizedBox(),
                    error: (e, _) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // ── White/dark bottom section ────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border.all(
                      color: AppColors.bgSurface, width: 0.5),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Category picker ──────────────────────────
                    categoriesAsync.when(
                      data: (cats) {
                        final filtered = cats
                            .where((c) => _type == 'income'
                                ? c.isIncome
                                : !c.isIncome)
                            .toList();
                        return SizedBox(
                          height: 88,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final cat = filtered[i];
                              final isSelected =
                                  _selectedCategory?.id ==
                                      cat.id;
                              final color =
                                  AppColors.fromHex(cat.color);
                              return GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 150),
                                  margin:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : AppColors.bgSurface,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: color
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                        child: Icon(
                                          _categoryIcon(cat.icon),
                                          color: color,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected
                                              ? color
                                              : AppColors
                                                  .textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const LinearProgressIndicator(
                              color: AppColors.teal),
                      error: (e, _) => Text('$e'),
                    ),

                    const Divider(height: 16),

                    // ── Numpad ───────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        child: Column(
                          children: [
                            _buildNumRow(['1', '2', '3']),
                            _buildNumRow(['4', '5', '6']),
                            _buildNumRow(['7', '8', '9']),
                            _buildNumRow(['.', '0', '⌫']),
                          ],
                        ),
                      ),
                    ),

                    // ── Save button ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSave
                                ? (_type == 'expense'
                                    ? AppColors.expense
                                    : AppColors.income)
                                : AppColors.bgSurface,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _selectedCategory == null
                                      ? 'Select a category'
                                      : _amount <= 0
                                          ? 'Enter an amount'
                                          : 'Save ${Formatters.currency(_amount)}',
                                  style: TextStyle(
                                    color: _canSave
                                        ? Colors.white
                                        : AppColors
                                            .textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final isBackspace = k == '⌫';
          return Expanded(
            child: GestureDetector(
              onTap: () => _onNumpad(k),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isBackspace
                      ? AppColors.bgSurface
                      : AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.bgSurface, width: 0.5),
                ),
                child: Center(
                  child: isBackspace
                      ? const Icon(Icons.backspace_outlined,
                          size: 20,
                          color: AppColors.textSecondary)
                      : Text(
                          k,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await ref.read(transactionsDaoProvider).insertTransaction(
          TransactionsCompanion.insert(
            amount: _amount,
            categoryId: _selectedCategory!.id,
            walletId: _selectedWallet!.id,
            type: _type,
            date: DateTime.now(),
            note: const Value(null),
          ),
        );
    if (mounted) {
      HapticFeedback.mediumImpact();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          content: Row(
            children: [
              Icon(
                _type == 'expense'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: _type == 'expense'
                    ? AppColors.expense
                    : AppColors.income,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${Formatters.currency(_amount)} saved to ${_selectedCategory!.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }
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