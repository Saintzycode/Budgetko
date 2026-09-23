import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/notifications/notification_triggers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() =>
      _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  static const _maxInputLength = 9;
  static const _quickAmounts = [50.0, 100.0, 500.0, 1000.0];

  String _type = 'expense';
  String _input = '';
  Category? _selectedCategory;
  Wallet? _selectedWallet;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_input) ?? 0;
  bool get _isExpense => _type == 'expense';
  Color get _typeColor =>
      _isExpense ? AppColors.expense : AppColors.income;
  bool get _canSave =>
      _amount > 0 &&
      _selectedCategory != null &&
      _selectedWallet != null &&
      !_saving;
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _onNumpad(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'back') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '.') {
        if (!_input.contains('.')) {
          _input = _input.isEmpty ? '0.' : '$_input.';
        }
      } else {
        if (_input.length >= _maxInputLength) return;
        _input = _input == '0' ? value : '$_input$value';
      }
    });
  }

  void _addQuick(double value) {
    HapticFeedback.lightImpact();
    final total = _amount + value;
    setState(() {
      _input = total % 1 == 0
          ? total.toInt().toString()
          : total.toStringAsFixed(2);
      if (_input.length > _maxInputLength) {
        _input = _input.substring(0, _maxInputLength);
      }
    });
  }

  void _setType(String type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _selectedCategory = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(allWalletsProvider);

    // Auto select first wallet
    walletsAsync.whenData((wallets) {
      if (_selectedWallet == null && wallets.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedWallet = wallets.first);
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/transactions');
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildAmountCard(),
                    const SizedBox(height: 10),
                    _buildQuickChips(),
                    const SizedBox(height: 12),
                    _buildNoteField(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Category'),
                    const SizedBox(height: 8),
                    _buildCategoryGrid(categoriesAsync),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Wallet'),
                    const SizedBox(height: 8),
                    _buildWalletRow(walletsAsync),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Amount'),
                    const SizedBox(height: 8),
                    _buildNumpad(),
                  ],
                ),
              ),
            ),
            _buildSaveBar(),
          ],
        ),
        ),
      ),
      );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary),
            onPressed: () => context.go('/transactions'),
          ),
          const Expanded(
            child: Text(
              'New transaction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.bgSurface,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isToday
                        ? 'Today'
                        : Formatters.dateShort(
                            _selectedDate),
                    style: const TextStyle(
                      color: AppColors.teal,
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
    );
  }

  // ── Amount hero card ─────────────────────────────────────────────────────

  Widget _buildAmountCard() {
    return GlowContainer(
      glowColor: _typeColor,
      glowRadius: 20,
      padding:
          const EdgeInsets.fromLTRB(20, 16, 20, 18),
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    'expense',
                    'Expense',
                    Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _buildTypeOption(
                    'income',
                    'Income',
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₱ ${_input.isEmpty ? "0" : _input}',
                style: TextStyle(
                  color: _typeColor,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedCategory?.name ?? 'Select a category',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
      String value, String label, IconData icon) {
    final selected = _type == value;
    final color = value == 'expense'
        ? AppColors.expense
        : AppColors.income;
    return GestureDetector(
      onTap: () => _setType(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? color
                  : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? color : AppColors.textHint,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick amounts ────────────────────────────────────────────────────────

  Widget _buildQuickChips() {
    return Row(
      children: _quickAmounts.map((v) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4),
            child: GestureDetector(
              onTap: () => _addQuick(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.bgSurface,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '+${v.toInt()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Note field ───────────────────────────────────────────────────────────

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLength: 200,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Add a note (optional)',
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.edit_outlined,
          color: AppColors.textHint,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.bgCard,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Category grid ────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(
      AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (cats) {
        final filtered = cats
            .where((c) => _isExpense
                ? !c.isIncome
                : c.isIncome)
            .toList();
        if (filtered.isEmpty) {
          return const Text(
            'No categories found',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final cat = filtered[i];
            final isSelected =
                _selectedCategory?.id == cat.id;
            final color = AppColors.fromHex(cat.color);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(
                    () => _selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppColors.bgSurface,
                    width: isSelected ? 1 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(
                                alpha: 0.25),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcon(cat.icon),
                      color: isSelected
                          ? color
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 4),
                      child: Text(
                        cat.name,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? color
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
          height: 60,
          child: Center(
              child: SpinKitRipple(
                  color: AppColors.teal, size: 28))),
      error: (e, _) => Text('$e'),
    );
  }

  // ── Wallet row ───────────────────────────────────────────────────────────

  Widget _buildWalletRow(
      AsyncValue<List<Wallet>> walletsAsync) {
    return walletsAsync.when(
      data: (wallets) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: wallets.map((w) {
            final isSelected =
                _selectedWallet?.id == w.id;
            final color = AppColors.fromHex(w.color);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(
                    () => _selectedWallet = w);
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 150),
                margin:
                    const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(18),
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
                      size: 13,
                      color: isSelected
                          ? color
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      w.name,
                      style: TextStyle(
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                        fontSize: 13,
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
    );
  }

  // ── Numpad ───────────────────────────────────────────────────────────────

  Widget _buildNumpad() {
    return Column(
      children: [
        _buildNumRow(['1', '2', '3']),
        _buildNumRow(['4', '5', '6']),
        _buildNumRow(['7', '8', '9']),
        _buildNumRow(['.', '0', 'back']),
      ],
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: keys.map((k) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4),
              child: _buildKey(k),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == 'back';
    return GestureDetector(
      onTap: () => _onNumpad(key),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isBackspace
              ? AppColors.bgSurface
              : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.bgSurface, width: 0.5),
        ),
        child: Center(
          child: isBackspace
              ? const Icon(Icons.backspace_outlined,
                  size: 20,
                  color: AppColors.textSecondary)
              : Text(
                  key,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Save bar ─────────────────────────────────────────────────────────────

  Widget _buildSaveBar() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(
            color: AppColors.bgSurface,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _canSave ? _typeColor : AppColors.bgSurface,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: SpinKitRipple(
                    color: Colors.white,
                    size: 20,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory == null
                          ? 'Select a category'
                          : _amount <= 0
                              ? 'Enter an amount'
                              : 'Save ${Formatters.currency(_amount)}',
                      style: TextStyle(
                        color: _canSave
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final now = DateTime.now();
    final category = _selectedCategory!;
    final amount = _amount;
    final type = _type;
    final walletId = _selectedWallet!.id;
    final noteText = _noteController.text.trim();
    try {
      await ref.read(transactionsDaoProvider).insertTransaction(
            TransactionsCompanion.insert(
              amount: amount,
              categoryId: category.id,
              walletId: walletId,
              type: type,
              date: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                now.hour,
                now.minute,
              ),
              note: noteText.isEmpty
                  ? const Value(null)
                  : Value(noteText.length > 200
                      ? noteText.substring(0, 200)
                      : noteText),
            ),
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    await notifyQuickAdd(
      db: ref.read(databaseProvider),
      amount: amount,
      categoryName: category.name,
      type: type,
    );
    await checkBudgetAlerts(ref.read(databaseProvider));
    if (!mounted) return;
    invalidateTransactionAggregates(ref);
    HapticFeedback.mediumImpact();
    context.go('/transactions');
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Row(
          children: [
            Icon(
              type == 'expense'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: type == 'expense'
                  ? AppColors.expense
                  : AppColors.income,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${Formatters.currency(amount)} saved to ${category.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
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
