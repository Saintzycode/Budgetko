import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../theme/app_theme.dart';

/// A category's budget for a given month, including any amount rolled
/// over from the previous month.
///
/// Rollover is derived from existing data rather than stored, so editing a
/// past transaction immediately changes the current month's available budget.
class CategoryBudgetStatus {
  final Category category;
  final double baseLimit;
  final double effectiveLimit;
  final double rolledOver;
  final double spent;
  final double previousSpent;

  const CategoryBudgetStatus({
    required this.category,
    required this.baseLimit,
    required this.effectiveLimit,
    required this.rolledOver,
    required this.spent,
    required this.previousSpent,
  });

  bool get hasRollover => rolledOver > 0;

  double get remaining =>
      (effectiveLimit - spent).clamp(0.0, double.infinity);

  double get progress => effectiveLimit > 0
      ? (spent / effectiveLimit).clamp(0.0, 1.0).toDouble()
      : 0.0;

  bool get isOver => effectiveLimit > 0 && spent > effectiveLimit;

  bool get isNear => !isOver && progress >= 0.8;

  Color get statusColor => isOver
      ? AppColors.expense
      : isNear
          ? AppColors.warning
          : AppColors.teal;
}

/// Computes the rollover for one category.
///
/// Capped at the category's own monthly limit so a category you rarely use
/// cannot accumulate an unlimited balance across many months.
///
/// [hasPriorData] guards the brand-new-user case: with no transactions in the
/// previous month at all there is no previous budget to roll forward, so the
/// rollover is zero rather than a full extra limit.
double computeRollover({
  required double baseLimit,
  required double previousSpent,
  required bool carryoverEnabled,
  required bool hasPriorData,
}) {
  if (!carryoverEnabled || !hasPriorData || baseLimit <= 0) {
    return 0;
  }
  return (baseLimit - previousSpent).clamp(0.0, baseLimit);
}
