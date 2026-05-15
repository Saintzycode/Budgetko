import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../core/router.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

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
          'Savings Goals',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.teal),
            onPressed: () => _showAddGoalSheet(context, ref),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('No savings goals yet',
                      style: TextStyle(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _showAddGoalSheet(context, ref),
                    child: const Text('Create first goal'),
                  ),
                ],
              ),
            );
          }

          final active =
              goals.where((g) => !g.isCompleted).toList();
          final completed =
              goals.where((g) => g.isCompleted).toList();

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
                ...active
                    .map((g) => _GoalCard(goal: g)),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Completed 🎉',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                ...completed
                    .map((g) => _GoalCard(goal: g)),
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

  void _showAddGoalSheet(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddGoalSheet(),
    );
  }
}

// ── Goal card ──────────────────────────────────────────────────────────────────

class _GoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final remaining = goal.targetAmount - goal.currentAmount;
    final color = AppColors.fromHex(goal.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlowContainer(
        glowColor: color,
        glowRadius: 12,
        padding: const EdgeInsets.all(16),
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings_outlined,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (goal.deadline != null)
                      Text(
                        'By ${Formatters.dateFull(goal.deadline!)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  if (!goal.isCompleted) ...[
                    // Subtract
                    GestureDetector(
                      onTap: () =>
                          _showSubtractDialog(context, ref),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.expense
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: AppColors.expense,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add
                    GestureDetector(
                      onTap: () =>
                          _showAddDialog(context, ref),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              color.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add,
                          color: color,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Delete
                  GestureDetector(
                    onTap: () =>
                        _confirmDelete(context, ref),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isCompleted
                    ? '✅ Goal reached!'
                    : '${Formatters.currency(remaining)} to go',
                style:
                    TextStyle(color: color, fontSize: 12),
              ),
              Text(
                '${Formatters.currency(goal.currentAmount)} / ${Formatters.currency(goal.targetAmount)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Add to "${goal.name}"',
            style: const TextStyle(
                color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
          style:
              const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
              labelText: 'Amount', prefixText: '₱ '),
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
              final amount =
                  double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(savingsGoalsDaoProvider)
                    .addToGoal(goal.id, amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                  backgroundColor: AppColors.bgCard,
                  content: Text(
                    '${Formatters.currency(amount)} added!',
                    style: const TextStyle(
                        color: AppColors.textPrimary),
                  ),
                ));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSubtractDialog(
      BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Subtract from "${goal.name}"',
            style: const TextStyle(
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${Formatters.currency(goal.currentAmount)}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Amount to subtract',
                  prefixText: '₱ '),
              autofocus: true,
            ),
          ],
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
              final amount =
                  double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(savingsGoalsDaoProvider)
                    .subtractFromGoal(goal.id, amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Subtract'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete goal?',
            style:
                TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${goal.name}"? This cannot be undone.',
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
                  .read(savingsGoalsDaoProvider)
                  .deleteGoal(goal.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Add goal sheet ─────────────────────────────────────────────────────────────

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() =>
      _AddGoalSheetState();
}

class _AddGoalSheetState
    extends ConsumerState<_AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  String _selectedColor = '#1D9E75';

  final List<String> _colors = [
    '#1D9E75', '#4B9FFF', '#FF6B6B',
    '#A78BFA', '#F59E0B', '#4ECDC4',
    '#F97316', '#EC4899',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
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
            const Text('New savings goal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Goal name'),
              validator: (v) => v == null || v.isEmpty
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _amountController,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target amount',
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

            // Color picker
            const Text('Color',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final isSelected = _selectedColor == c;
                final color = AppColors.fromHex(c);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Deadline
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now()
                      .add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
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
                  setState(() => _deadline = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.bgSurface,
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _deadline != null
                          ? Formatters.dateFull(_deadline!)
                          : 'Set deadline (optional)',
                      style: TextStyle(
                        color: _deadline != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(savingsGoalsDaoProvider).insertGoal(
          SavingsGoalsCompanion.insert(
            name: _nameController.text,
            targetAmount:
                double.parse(_amountController.text),
            color: Value(_selectedColor),
            deadline: Value(_deadline),
          ),
        );
    if (mounted) Navigator.pop(context);
  }
}
