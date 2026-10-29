import 'package:flutter/material.dart';

import 'record.dart';

/// A category definition. Icons are Material equivalents of the line icons
/// used by the prototype, with the same tint pairs.
@immutable
class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.ring,
  });

  final String id;
  final String name;
  final RecordType type;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color ring;
}

abstract final class LedgerCategories {
  static const List<LedgerCategory> expense = <LedgerCategory>[
    LedgerCategory(
      id: 'food',
      name: '餐饮',
      type: RecordType.expense,
      icon: Icons.ramen_dining_outlined,
      background: Color(0xFFE7EFFA),
      foreground: Color(0xFF1F5EA8),
      ring: Color(0x261F5EA8),
    ),
    LedgerCategory(
      id: 'transport',
      name: '交通',
      type: RecordType.expense,
      icon: Icons.directions_bus_outlined,
      background: Color(0xFFFBF0DA),
      foreground: Color(0xFF8A5F08),
      ring: Color(0x268A5F08),
    ),
    LedgerCategory(
      id: 'shopping',
      name: '购物',
      type: RecordType.expense,
      icon: Icons.shopping_bag_outlined,
      background: Color(0xFFFCEDE2),
      foreground: Color(0xFFA8551A),
      ring: Color(0x26A8551A),
    ),
    LedgerCategory(
      id: 'fun',
      name: '娱乐',
      type: RecordType.expense,
      icon: Icons.sports_esports_outlined,
      background: Color(0xFFFCEBF2),
      foreground: Color(0xFFA23A66),
      ring: Color(0x26A23A66),
    ),
    LedgerCategory(
      id: 'home',
      name: '居家',
      type: RecordType.expense,
      icon: Icons.home_outlined,
      background: Color(0xFFE6F4EC),
      foreground: Color(0xFF0A6B51),
      ring: Color(0x260A6B51),
    ),
    LedgerCategory(
      id: 'medical',
      name: '医疗',
      type: RecordType.expense,
      icon: Icons.medical_services_outlined,
      background: Color(0xFFECEAF9),
      foreground: Color(0xFF46367F),
      ring: Color(0x2646367F),
    ),
    LedgerCategory(
      id: 'study',
      name: '学习',
      type: RecordType.expense,
      icon: Icons.menu_book_outlined,
      background: Color(0xFFE7EFFA),
      foreground: Color(0xFF1F5EA8),
      ring: Color(0x261F5EA8),
    ),
    LedgerCategory(
      id: 'repay',
      name: '还款',
      type: RecordType.expense,
      icon: Icons.credit_card_outlined,
      background: Color(0xFFE8F3E4),
      foreground: Color(0xFF2A6B1C),
      ring: Color(0x262A6B1C),
    ),
    LedgerCategory(
      id: 'packet',
      name: '红包',
      type: RecordType.expense,
      icon: Icons.redeem_outlined,
      background: Color(0xFFFCEAE8),
      foreground: Color(0xFFA8362F),
      ring: Color(0x26A8362F),
    ),
    LedgerCategory(
      id: 'other',
      name: '其他',
      type: RecordType.expense,
      icon: Icons.more_horiz_rounded,
      background: Color(0xFFEEF1EE),
      foreground: Color(0xFF5F6B65),
      ring: Color(0x265F6B65),
    ),
  ];

  static const List<LedgerCategory> income = <LedgerCategory>[
    LedgerCategory(
      id: 'salary',
      name: '工资',
      type: RecordType.income,
      icon: Icons.account_balance_wallet_outlined,
      background: Color(0xFFE6F4EC),
      foreground: Color(0xFF0A6B51),
      ring: Color(0x260A6B51),
    ),
    LedgerCategory(
      id: 'bonus',
      name: '奖金',
      type: RecordType.income,
      icon: Icons.card_giftcard_outlined,
      background: Color(0xFFFCEDE2),
      foreground: Color(0xFFA8551A),
      ring: Color(0x26A8551A),
    ),
    LedgerCategory(
      id: 'parttime',
      name: '兼职',
      type: RecordType.income,
      icon: Icons.work_outline_rounded,
      background: Color(0xFFE7EFFA),
      foreground: Color(0xFF1F5EA8),
      ring: Color(0x261F5EA8),
    ),
    LedgerCategory(
      id: 'invest',
      name: '理财',
      type: RecordType.income,
      icon: Icons.trending_up_rounded,
      background: Color(0xFFECEAF9),
      foreground: Color(0xFF46367F),
      ring: Color(0x2646367F),
    ),
    LedgerCategory(
      id: 'redpacket',
      name: '红包',
      type: RecordType.income,
      icon: Icons.mark_email_unread_outlined,
      background: Color(0xFFFCEBF2),
      foreground: Color(0xFFA23A66),
      ring: Color(0x26A23A66),
    ),
    LedgerCategory(
      id: 'otherin',
      name: '其他',
      type: RecordType.income,
      icon: Icons.more_horiz_rounded,
      background: Color(0xFFEEF1EE),
      foreground: Color(0xFF5F6B65),
      ring: Color(0x265F6B65),
    ),
  ];

  static const List<LedgerCategory> all = <LedgerCategory>[
    ...expense,
    ...income,
  ];

  static List<LedgerCategory> forType(RecordType type) {
    return type == RecordType.expense ? expense : income;
  }

  static LedgerCategory byId(
    String id, {
    RecordType type = RecordType.expense,
  }) {
    final list = forType(type);
    for (final category in list) {
      if (category.id == id) return category;
    }
    return list.last;
  }
}
