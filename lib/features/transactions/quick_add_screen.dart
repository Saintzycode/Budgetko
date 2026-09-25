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
import '../../../../core/utils/category_icons.dart';

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

  String get _origin {
    final from = GoRouterState.of(context).uri
        .queryParameters['from'];
    if (from == null || from.isEmpty) return '/transactions';
    if (!from.startsWith('/')) return '/transactions';
    if (from == '/quick-add') return '/transactions';
    return from;
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

    // The keyboard overlays the window rather than shrinking it, so the
    // body still receives full height. Applying viewInsets as padding here
    // would lift the save bar on every keyboard animation, so the layout
    // stays static and only the numpad reacts to the keyboard.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // viewPadding is the raw display inset and does not change when the
    // keyboard opens, unlike padding, which drops to zero. Using it keeps
    // the save bar pinned to the same spot throughout the keyboard
    // animation.
    final stableBottom = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(_origin);
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _buildAmountCard(),
            ),
            Expanded(
              flex: keyboardOpen ? 1 : 2,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    _buildSelectorRow(
                        categoriesAsync, walletsAsync),
                    const SizedBox(height: 10),
                    _buildQuickChips(),
                  ],
                ),
              ),
            ),
            if (!keyboardOpen)
              Expanded(flex: 3, child: _buildNumpad()),
            _buildSaveBar(stableBottom),
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
            onPressed: () => context.go(_origin),
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
      glowRadius: 18,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₱ ${_input.isEmpty ? "0" : _input}',
                style: TextStyle(
                  color: _typeColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
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

  // ── Selector row ─────────────────────────────────────────────────────────

  Widget _buildSelectorRow(
    AsyncValue<List<Category>> catsAsync,
    AsyncValue<List<Wallet>> walletsAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: _FieldShell(
            icon: Icons.category_outlined,
            child: catsAsync.when(
              data: (cats) {
                final filtered = cats
                    .where((c) =>
                        _isExpense ? !c.isIncome : c.isIncome)
                    .toList();
                final selectedId = filtered
                        .any((c) => c.id == _selectedCategory?.id)
                    ? _selectedCategory?.id
                    : null;
                return DropdownButton<int?>(
                  value: selectedId,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.expand_more,
                      color: AppColors.textHint, size: 18),
                  hint: Text(
                    'Category',
                    style: TextStyle(
                      color: _selectedCategory == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  items: [
                    for (final cat in filtered)
                      DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(
                              categoryIconData(cat.icon),
                              size: 15,
                              color: AppColors.fromHex(
                                  cat.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory =
                        filtered.firstWhere((c) => c.id == v));
                  },
                );
              },
              loading: () => const SpinKitRipple(
                  color: AppColors.teal, size: 18),
              error: (e, _) => Text('$e',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FieldShell(
            icon: Icons.account_balance_wallet_outlined,
            child: walletsAsync.when(
              data: (wallets) {
                final selectedId = wallets
                        .any((w) => w.id == _selectedWallet?.id)
                    ? _selectedWallet?.id
                    : null;
                return DropdownButton<int?>(
                  value: selectedId,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.expand_more,
                      color: AppColors.textHint, size: 18),
                  hint: const Text(
                    'Wallet',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  items: [
                    for (final w in wallets)
                      DropdownMenuItem<int?>(
                        value: w.id,
                        child: Row(
                          children: [
                            Icon(
                              walletIconData(w.type),
                              size: 15,
                              color: AppColors.fromHex(
                                  w.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w.name,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _selectedWallet = wallets
                        .firstWhere((w) => w.id == v));
                  },
                );
              },
              loading: () => const SpinKitRipple(
                  color: AppColors.teal, size: 18),
              error: (e, _) => Text('$e',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Numpad ───────────────────────────────────────────────────────────────

  Widget _buildNumpad() {
    return Column(
      children: [
        Expanded(child: _buildNumRow(['1', '2', '3'])),
        Expanded(child: _buildNumRow(['4', '5', '6'])),
        Expanded(child: _buildNumRow(['7', '8', '9'])),
        Expanded(child: _buildNumRow(['.', '0', 'back'])),
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

  Widget _buildSaveBar(double bottomInset) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
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

    final wantsNote = await _askAddNote();
    if (!mounted) return;

    String? note;
    if (wantsNote) {
      final entered = await _promptForNote();
      if (!mounted) return;
      if (entered == null) return;
      note = entered.isEmpty ? null : entered;
    }

    await _persist(note);
  }

  Future<bool> _askAddNote() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Add a note?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Do you want to add some note in this transaction?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _promptForNote() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
  }

  Future<void> _persist(String? note) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final now = DateTime.now();
    final category = _selectedCategory!;
    final amount = _amount;
    final type = _type;
    final walletId = _selectedWallet!.id;
    final noteText = note?.trim() ?? '';
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
    context.go(_origin);
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
}

class _FieldShell extends StatelessWidget {
  final IconData icon;
  final Widget child;
  const _FieldShell({
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.bgSurface, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Your note',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 200,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. Lunch with the team',
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
          ),
          counterText: '',
          filled: true,
          fillColor: AppColors.bgSurface,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.bgSurface,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.teal,
              width: 1,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text(
            'Skip',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
          ),
          child: const Text('Add note'),
        ),
      ],
    );
  }
}
