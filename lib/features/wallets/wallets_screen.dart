import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(allWalletsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu,
                color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Wallets',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.teal),
            onPressed: () => _showAddWalletSheet(context, ref),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No wallets yet',
                    style: TextStyle(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _showAddWalletSheet(context, ref),
                    child: const Text('Add wallet'),
                  ),
                ],
              ),
            );
          }

          // Calculate total balance
          final totalBalance = wallets.fold(
              0.0, (sum, w) => sum + w.balance);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 120),
            children: [
              // ── Total balance card ─────────────────────────
              GlowContainer(
                glowColor: AppColors.teal,
                glowRadius: 30,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(totalBalance),
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${wallets.length} wallet${wallets.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'My Wallets',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // ── Wallet cards ───────────────────────────────
              ...wallets.map(
                  (w) => _WalletCard(wallet: w)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.teal),
        ),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddWalletSheet(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddWalletSheet(),
    );
  }
}

// ── Wallet card ────────────────────────────────────────────────────────────────

class _WalletCard extends ConsumerWidget {
  final Wallet wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.fromHex(wallet.color);

    return GlowContainer(
      glowColor: color,
      glowRadius: 15,
      padding: const EdgeInsets.all(16),
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            children: [
              // Wallet icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _walletIcon(wallet.type),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (wallet.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.teal
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _walletTypeName(wallet.type),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                color: AppColors.bgSurface,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => _showEditBalanceDialog(
                        context, ref),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: AppColors.textPrimary,
                            size: 18),
                        SizedBox(width: 8),
                        Text('Edit balance',
                            style: TextStyle(
                                color:
                                    AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  if (!wallet.isDefault)
                    PopupMenuItem(
                      onTap: () =>
                          _setAsDefault(context, ref),
                      child: const Row(
                        children: [
                          Icon(Icons.star_outline,
                              color: AppColors.teal,
                              size: 18),
                          SizedBox(width: 8),
                          Text('Set as default',
                              style: TextStyle(
                                  color: AppColors.teal)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () =>
                        _confirmDelete(context, ref),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppColors.expense,
                            size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(
                                color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Balance
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13),
              ),
              Text(
                Formatters.currency(wallet.balance),
                style: TextStyle(
                  color: wallet.balance >= 0
                      ? color
                      : AppColors.expense,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _walletIcon(String type) {
    return switch (type) {
      'cash' => Icons.payments_outlined,
      'gcash' => Icons.phone_android_outlined,
      'bank' => Icons.account_balance_outlined,
      _ => Icons.wallet_outlined,
    };
  }

  String _walletTypeName(String type) {
    return switch (type) {
      'cash' => 'Cash Wallet',
      'gcash' => 'GCash',
      'bank' => 'Bank Account',
      _ => 'Wallet',
    };
  }

  void _showEditBalanceDialog(
      BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: wallet.balance.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Edit ${wallet.name} balance',
          style: const TextStyle(
              color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true),
          style:
              const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Balance',
            prefixText: '₱ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v =
                  double.tryParse(controller.text);
              if (v != null) {
                ref
                    .read(walletsDaoProvider)
                    .updateBalance(wallet.id, v);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(
      BuildContext context, WidgetRef ref) {
    ref.read(walletsDaoProvider).updateWallet(
          wallet.copyWith(isDefault: true),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          '${wallet.name} set as default',
          style:
              const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete wallet?',
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${wallet.name}"?',
          style: const TextStyle(
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense),
            onPressed: () {
              ref
                  .read(walletsDaoProvider)
                  .deleteWallet(wallet.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Add wallet sheet ───────────────────────────────────────────────────────────

class _AddWalletSheet extends ConsumerStatefulWidget {
  const _AddWalletSheet();

  @override
  ConsumerState<_AddWalletSheet> createState() =>
      _AddWalletSheetState();
}

class _AddWalletSheetState
    extends ConsumerState<_AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _type = 'cash';

  final List<Map<String, dynamic>> _types = [
    {
      'key': 'cash',
      'label': 'Cash',
      'icon': Icons.payments_outlined,
      'color': '#1D9E75',
    },
    {
      'key': 'gcash',
      'label': 'GCash',
      'icon': Icons.phone_android_outlined,
      'color': '#007DFF',
    },
    {
      'key': 'bank',
      'label': 'Bank',
      'icon': Icons.account_balance_outlined,
      'color': '#AB47BC',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const Text(
              'Add wallet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Type selector
            Row(
              children: _types.map((t) {
                final isSelected = _type == t['key'];
                final color =
                    AppColors.fromHex(t['color'] as String);
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _type = t['key']),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppColors.bgSurface,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            t['icon'] as IconData,
                            color: isSelected
                                ? color
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Wallet name'),
              validator: (v) => v == null || v.isEmpty
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 12),

            // Initial balance
            TextFormField(
              controller: _balanceController,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: const InputDecoration(
                labelText: 'Initial balance',
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Add wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedType = _types
        .firstWhere((t) => t['key'] == _type);
    await ref.read(walletsDaoProvider).insertWallet(
          WalletsCompanion.insert(
            name: _nameController.text,
            type: _type,
            icon: _type,
            color: selectedType['color'] as String,
            balance: Value(
              double.tryParse(_balanceController.text) ??
                  0,
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }
}