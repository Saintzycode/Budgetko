import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => showCategoryEditor(context, ref),
            icon: const Icon(Icons.add,
                color: AppColors.teal),
          ),
        ],
      ),
      body: catsAsync.when(
        data: (cats) {
          final expense =
              cats.where((c) => !c.isIncome).toList();
          final income = cats.where((c) => c.isIncome).toList();
          return ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (expense.isEmpty && income.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      const Icon(
                          Icons.category_outlined,
                          color: AppColors.textHint,
                          size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'No categories yet',
                        style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            showCategoryEditor(
                                context, ref),
                        icon: const Icon(Icons.add,
                            size: 18,
                            color: Colors.white),
                        label: const Text(
                            'Add category',
                            style: TextStyle(
                                color: Colors.white)),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.teal,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (expense.isNotEmpty) ...[
                const _GroupLabel('Expense'),
                const SizedBox(height: 8),
                ...expense.map((c) => _CategoryRow(
                    category: c)),
              ],
              if (income.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _GroupLabel('Income'),
                const SizedBox(height: 8),
                ...income.map((c) => _CategoryRow(
                    category: c)),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: SpinKitRipple(
              color: AppColors.teal, size: 42),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(
                  color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String title;
  const _GroupLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  final Category category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.fromHex(category.color);
    final limit = category.monthlyLimit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => showCategoryEditor(context, ref,
            existing: category),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.bgSurface, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIconData(category.icon),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      limit != null && limit > 0
                          ? 'Monthly limit set'
                          : 'No limit',
                      style: const TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (limit != null && limit > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    _compact(limit),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Delete',
                visualDensity:
                    VisualDensity.compact,
                onPressed: () =>
                    _confirmDelete(context, ref),
                icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textHint,
                    size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1000000) {
      return '₱${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '₱${(v / 1000).toStringAsFixed(1)}K';
    }
    return '₱${v.toStringAsFixed(0)}';
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final txCount = await ref
        .read(transactionsDaoProvider)
        .countTransactionsForCategory(category.id);
    final recurring = await ref
        .read(recurringDaoProvider)
        .getActiveRecurring();
    final recurringCount = recurring
        .where((r) => r.categoryId == category.id)
        .length;

    if (!context.mounted) return;

    if (txCount > 0 || recurringCount > 0) {
      final parts = <String>[];
      if (txCount > 0) {
        parts.add('$txCount transaction${txCount == 1 ? '' : 's'}');
      }
      if (recurringCount > 0) {
        parts.add('$recurringCount recurring item${recurringCount == 1 ? '' : 's'}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 4),
          content: Text(
            'Cannot delete "${category.name}" — used by ${parts.join(' and ')}. Remove those first.',
            style: const TextStyle(
                color: AppColors.textPrimary),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardLight,
        title: Text('Delete "${category.name}"?',
            style:
                const TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This category is not used by any transaction.',
          style: TextStyle(color: AppColors.textSecondary),
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
    if (confirmed != true) return;
    await ref
        .read(categoriesDaoProvider)
        .deleteCategory(category.id);
  }
}

// ── Editor ─────────────────────────────────────────────────────────────────────

Future<void> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? existing,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CategoryEditor(existing: existing),
  );
}

class _CategoryEditor extends ConsumerStatefulWidget {
  final Category? existing;
  const _CategoryEditor({this.existing});

  @override
  ConsumerState<_CategoryEditor> createState() =>
      _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late String _icon;
  late String _color;
  late bool _isIncome;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _limitController = TextEditingController(
      text: (c?.monthlyLimit ?? 0) > 0
          ? _trimNumber(c!.monthlyLimit!)
          : '',
    );
    _icon = c?.icon ?? 'food';
    _color = c?.color ?? categoryColorOptions.first;
    _isIncome = c?.isIncome ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  String _trimNumber(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  double? get _limit {
    final raw = _limitController.text
        .replaceAll(',', '')
        .trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return v;
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final limit = _limit;
    final existing = widget.existing;
    final dao = ref.read(categoriesDaoProvider);
    if (existing == null) {
      await dao.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          icon: _icon,
          color: _color,
          monthlyLimit: Value(limit),
          isIncome: Value(_isIncome),
        ),
      );
    } else {
      await dao.updateCategory(
        Category(
          id: existing.id,
          name: name,
          icon: _icon,
          color: _color,
          monthlyLimit: limit,
          isIncome: _isIncome,
          createdAt: existing.createdAt,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          _isNew ? 'Category added' : 'Category updated',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = AppColors.fromHex(_color);
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
                Text(
                  _isNew ? 'New category' : 'Edit category',
                  style: const TextStyle(
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
                        current: _isIncome ? 'income' : 'expense',
                        onTap: () =>
                            setState(() => _isIncome = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeToggle(
                        value: 'income',
                        label: 'Income',
                        current: _isIncome ? 'income' : 'expense',
                        onTap: () =>
                            setState(() => _isIncome = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: previewColor.withValues(
                            alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                            color: previewColor,
                            width: 1),
                      ),
                      child: Icon(
                        categoryIconData(_icon),
                        color: previewColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        maxLength: 50,
                        maxLengthEnforcement:
                            MaxLengthEnforcement.enforced,
                        autofocus: _isNew,
                        style: const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 15),
                        decoration:
                            InputDecoration(
                          hintText: 'Category name',
                          hintStyle: const TextStyle(
                              color:
                                  AppColors.textHint,
                              fontSize: 15),
                          filled: true,
                          fillColor:
                              AppColors.bgSurface,
                          counterText: '',
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors.bgSurface,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                            borderSide:
                                const BorderSide(
                              color: AppColors.teal,
                              width: 1,
                            ),
                          ),
                        ),
                        onChanged: (_) =>
                            setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Icon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      categoryIconOptions.entries.map((e) {
                    final selected = _icon == e.key;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _icon = e.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? previewColor.withValues(
                                  alpha: 0.2)
                              : AppColors.bgSurface,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? previewColor
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          e.value,
                          size: 19,
                          color: selected
                              ? previewColor
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      categoryColorOptions.map((hex) {
                    final selected = _color == hex;
                    final c = AppColors.fromHex(hex);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _color = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 16,
                                color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                if (!_isIncome) ...[
                  const SizedBox(height: 18),
                  const _FieldLabel('Monthly limit (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _limitController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      hintText: 'e.g. 2000',
                      hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 15),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.bgSurface,
                            width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.teal,
                            width: 1),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSave
                          ? AppColors.teal
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
                            _canSave
                                ? (_isNew
                                    ? 'Add category'
                                    : 'Save changes')
                                : 'Enter a name',
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
              color: selected
                  ? color
                  : AppColors.textHint,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
