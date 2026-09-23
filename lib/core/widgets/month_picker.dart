import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MonthPickerSheet(
      initial: initial,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthPickerSheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late int _year;
  int get _currentYear => DateTime.now().year;
  int get _currentMonth => DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year
        .clamp(widget.firstDate.year, widget.lastDate.year)
        .toInt();
  }

  bool _isOutOfRange(int month) {
    if (_year < widget.firstDate.year ||
        (_year == widget.firstDate.year && month < widget.firstDate.month)) {
      return true;
    }
    if (_year > widget.lastDate.year ||
        (_year == widget.lastDate.year && month > widget.lastDate.month)) {
      return true;
    }
    return false;
  }

  void _previousYear() {
    if (_year <= widget.firstDate.year) return;
    setState(() => _year--);
  }

  void _nextYear() {
    if (_year >= widget.lastDate.year) return;
    setState(() => _year++);
  }

  void _pickMonth(int month) {
    Navigator.of(context).pop(DateTime(_year, month));
  }

  @override
  Widget build(BuildContext context) {
    final isSelectedYear = widget.initial.year == _year;
    final isCurrentYear = _year == _currentYear;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Select month',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _YearArrow(
                icon: Icons.chevron_left,
                onTap: _previousYear,
                enabled: _year > widget.firstDate.year,
              ),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _YearArrow(
                icon: Icons.chevron_right,
                onTap: _nextYear,
                enabled: _year < widget.lastDate.year,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: List.generate(12, (i) {
              final month = i + 1;
              final disabled = _isOutOfRange(month);
              final selected =
                  isSelectedYear && widget.initial.month == month;
              final isCurrent =
                  isCurrentYear && _currentMonth == month;
              return _MonthCell(
                label: _monthLabels[i],
                selected: selected,
                disabled: disabled,
                isCurrent: isCurrent,
                onTap: () => _pickMonth(month),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(DateTime(_currentYear, _currentMonth)),
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Go to current month',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _YearArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _YearArrow({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon,
          color: enabled ? AppColors.textPrimary : AppColors.textHint),
      onPressed: enabled ? onTap : null,
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MonthCell({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? AppColors.teal
        : AppColors.bgSurface;
    final fgColor = selected
        ? Colors.white
        : disabled
            ? AppColors.textHint
            : AppColors.textPrimary;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent && !selected
                ? AppColors.teal.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isCurrent && !selected)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}