import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../gamification/savings_stats.dart';
import '../utils/formatters.dart';

/// Level, XP progress and savings streak shown above the goal list.
class SavingsHud extends StatelessWidget {
  final SavingsStats stats;
  const SavingsHud({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final xp = savingsXp(stats.totalDeposited);
    final level = savingsLevel(xp);
    final progress = savingsLevelProgress(xp);
    final nextAt = savingsXpAtLevelStart(level) +
        savingsXpForNextLevel(level);
    final title = savingsLevelTitle(level);
    final onStreak = stats.weekStreak > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$level',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'LVL',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Tooltip(
                      message: 'Every ${Formatters.currency(
                        kXpPerPeso,
                      )} deposited earns 1 XP',
                      child: Text(
                        '${_compact(xp.toDouble())} XP  ·  '
                        '${_compact((nextAt - xp).toDouble())} to level ${level + 1}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _StreakChip(
                weeks: stats.weekStreak,
                best: stats.bestWeekStreak,
                active: onStreak,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.bgSurface,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Saved total',
                  value: Formatters.currencyCompact(
                      stats.totalSaved),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'This month',
                  value:
                      Formatters.currencyCompact(stats.savedThisMonth),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Last 30 days',
                  value:
                      Formatters.currencyCompact(stats.savedLast30Days),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _compact(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.round().toString();
  }
}

class _StreakChip extends StatelessWidget {
  final int weeks;
  final int best;
  final bool active;
  const _StreakChip({
    required this.weeks,
    required this.best,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.warning : AppColors.textHint;
    return Tooltip(
      message: best > 0
          ? 'Best run: $best week${best == 1 ? '' : 's'}'
          : 'Deposit each week to build a streak',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 15,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              weeks == 0 ? 'No streak' : '$weeks wk',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// The four milestone pips shown under a goal's progress bar.
class MilestonePips extends StatelessWidget {
  final double progress;
  final Color color;
  const MilestonePips({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in Milestone.all) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: m.isReached(progress)
                        ? (m.at >= 1
                            ? AppColors.warning
                            : color)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  m.label,
                  style: TextStyle(
                    color: m.isReached(progress)
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                    fontSize: 8,
                    fontWeight: m.isReached(progress)
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ].toList()
        ..removeLast(),
    );
  }
}
