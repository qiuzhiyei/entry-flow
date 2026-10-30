import 'package:intl/intl.dart';

import '../models/record.dart';

abstract final class Money {
  static final NumberFormat _decimal = NumberFormat('#,##0.00', 'zh_CN');
  static final NumberFormat _integer = NumberFormat('#,##0', 'zh_CN');

  /// `¥1,234.56`, with the sign in front of the currency symbol.
  static String formatCents(int cents) {
    final negative = cents < 0;
    final text = _decimal.format(cents.abs() / 100);
    return '${negative ? '-' : ''}¥$text';
  }

  /// `−¥42.50` for an expense, `+¥800.00` for income.
  static String signedCents(int cents, RecordType type) {
    final sign = type == RecordType.expense ? '−' : '+';
    return '$sign${formatCents(cents.abs())}';
  }

  /// Whole-yuan variant used by compact stat tiles.
  static String formatShortCents(int cents) {
    final negative = cents < 0;
    final text = _integer.format(cents.abs() / 100);
    return '${negative ? '-' : ''}¥$text';
  }

  /// Formats the raw keypad buffer (`1234.5` -> `1,234.5`) without forcing
  /// two decimals while the user is still typing.
  static String formatInput(String raw) {
    final parts = raw.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    final formatted = _integer.format(whole);
    return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }
}

abstract final class Dates {
  static const List<String> _weekdays = <String>[
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

  static String cnDate(DateTime date) => '${date.month}月${date.day}日';

  static String slashDate(DateTime date) {
    return '${date.year}/${_two(date.month)}/${_two(date.day)}';
  }

  static String monthLabel(DateTime date) => '${date.year}年${date.month}月';

  static String monthShort(DateTime date) => '${date.month}月';

  static DateTime dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static String dayLabel(DateTime day, {DateTime? now}) {
    final today = dayOnly(now ?? DateTime.now());
    final target = dayOnly(day);
    final difference = target.difference(today).inDays;
    if (difference == 0) return '今天 · ${cnDate(day)}';
    if (difference == -1) return '昨天 · ${cnDate(day)}';
    return '${cnDate(day)} · ${weekday(day)}';
  }

  static String backupLabel(DateTime? lastBackup, {DateTime? now}) {
    if (lastBackup == null) return '还没有备份过';
    final current = now ?? DateTime.now();
    final lastDay = dayOnly(lastBackup);
    final today = dayOnly(current);
    final difference = today.difference(lastDay).inDays;
    final time = '${_two(lastBackup.hour)}:${_two(lastBackup.minute)}';
    if (difference == 0) return '上次备份：今天 $time';
    if (difference == 1) return '上次备份：昨天 $time';
    return '上次备份：${lastBackup.month}月${lastBackup.day}日 $time';
  }

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 9) return '早上好';
    if (hour >= 9 && hour < 12) return '上午好';
    if (hour >= 12 && hour < 14) return '中午好';
    if (hour >= 14 && hour < 18) return '下午好';
    return '晚上好';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
