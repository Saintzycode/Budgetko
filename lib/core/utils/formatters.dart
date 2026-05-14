import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'fil_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static final _currencyCompact = NumberFormat.compactCurrency(
    locale: 'fil_PH',
    symbol: '₱',
    decimalDigits: 1,
  );

  static final _dateShort = DateFormat('MMM d');
  static final _dateFull = DateFormat('MMMM d, yyyy');
  static final _dateMonth = DateFormat('MMMM yyyy');
  static final _dateMonthShort = DateFormat('MMM yyyy');
  static final _time = DateFormat('h:mm a');
  static final _dayOfWeek = DateFormat('EEEE');

  static String currency(double amount) => _currency.format(amount);
  static String currencyCompact(double amount) =>
      _currencyCompact.format(amount);
  static String dateShort(DateTime date) => _dateShort.format(date);
  static String dateFull(DateTime date) => _dateFull.format(date);
  static String month(DateTime date) => _dateMonth.format(date);
  static String monthShort(DateTime date) =>
      _dateMonthShort.format(date);
  static String time(DateTime date) => _time.format(date);
  static String dayOfWeek(DateTime date) => _dayOfWeek.format(date);

  static String percent(double value) =>
      '${value.toStringAsFixed(1)}%';

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return dateShort(date);
  }

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  static String weekdayName(int day) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[(day - 1).clamp(0, 6)];
  }
}