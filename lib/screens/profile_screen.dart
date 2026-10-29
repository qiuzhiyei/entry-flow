import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../models/ledger.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openLedgerSheet(BuildContext context) async {
    final provider = context.read<LedgerProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (sheetContext) => _LedgerSheet(provider: provider),
    );
  }

  Future<void> _toggleReminder(BuildContext context) async {
    final provider = context.read<LedgerProvider>();
    final enabled = !provider.reminderEnabled;
    await provider.setReminderEnabled(enabled);
    if (!context.mounted) return;
    showAppToast(enabled ? '已开启每日提醒' : '已关闭每日提醒');
  }

  Future<void> _backup(BuildContext context) async {
    try {
      await context.read<LedgerProvider>().backupNow();
      if (!context.mounted) return;
      showAppToast('数据已备份到本机');
    } catch (_) {
      if (!context.mounted) return;
      showAppToast('备份失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final now = DateTime.now();
    final used = ledger.currentMonthExpenseCents;
    final budget = LedgerProvider.budgetCents;
    final progress = (used / budget).clamp(0.0, 1.0).toDouble();
    final over = used > budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Text('我的', style: AppText.screenTitle),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const _UserCard(),
              const SizedBox(height: 14),
              _BudgetCard(
                usedCents: used,
                budgetCents: budget,
                progress: progress,
                over: over,
                monthLabel: Dates.monthShort(now),
              ),
              _SectionHead('账本管理'),
              _ListCard(
                children: <Widget>[
                  _LedgerRow(
                    ledger: ledger.selectedLedger,
                    subtitle:
                        '本月 ${ledger.currentMonthCount} 笔 · '
                        '${Ledgers.all.length} 个账本',
                    onTap: () => _openLedgerSheet(context),
                  ),
                ],
              ),
              _SectionHead('通用设置'),
              _ListCard(
                children: <Widget>[
                  _ReminderRow(
                    enabled: ledger.reminderEnabled,
                    onTap: () => _toggleReminder(context),
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.file_download_outlined,
                    title: '数据备份',
                    subtitle: _backupLabel(ledger.lastBackupAt, now),
                    onTap: () => _backup(context),
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.info_outline_rounded,
                    title: '关于记账本',
                    subtitle: '丘知叶 开发 · 本地运行 v1.0',
                    onTap: () => showAppToast('记账本 v1.0 · 开发者 丘知叶'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '本地应用，无需登录 · 数据只保存在本机',
                  style: TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _backupLabel(DateTime? lastBackup, DateTime now) {
    if (lastBackup == null) return '还没有备份过';
    final lastDay = Dates.dayOnly(lastBackup);
    final today = Dates.dayOnly(now);
    final difference = today.difference(lastDay).inDays;
    final time =
        '${lastBackup.hour.toString().padLeft(2, '0')}:'
        '${lastBackup.minute.toString().padLeft(2, '0')}';
    if (difference == 0) return '上次备份：今天 $time';
    if (difference == 1) return '上次备份：昨天 $time';
    return '上次备份：${lastBackup.month}月${lastBackup.day}日 $time';
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mintBorder),
            ),
            child: const Text(
              '丘',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.mintInk,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '丘知叶',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.17,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '本地记账本 · 无需登录',
                  style: TextStyle(fontSize: 11.5, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.star_border_rounded,
                  size: 16,
                  color: AppColors.amberInk,
                ),
                SizedBox(width: 4),
                Text(
                  '开发者',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amberInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.usedCents,
    required this.budgetCents,
    required this.progress,
    required this.over,
    required this.monthLabel,
  });

  final int usedCents;
  final int budgetCents;
  final double progress;
  final bool over;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '本月预算',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.145,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                monthLabel,
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                Money.formatShortCents(usedCents),
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${Money.formatShortCents(budgetCents)}',
                style: const TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.mintTint,
              color: over ? AppColors.danger : AppColors.mint,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                over
                    ? '已超支 ${Money.formatShortCents(usedCents - budgetCents)}'
                    : '已用 ${(progress * 100).round()}%',
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
              const Spacer(),
              Text(
                over
                    ? '预算 ${Money.formatShortCents(budgetCents)}'
                    : '剩余 ${Money.formatShortCents(budgetCents - usedCents)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.list),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.list),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.line2);
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: AppColors.mintInk),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.ledger,
    required this.subtitle,
    required this.onTap,
  });

  final Ledger ledger;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Row(
          children: <Widget>[
            const _RowIcon(Icons.menu_book_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ledger.name,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: enabled,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Row(
            children: <Widget>[
              const _RowIcon(Icons.notifications_none_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '每日记账提醒',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? '每天 21:00 提醒我记一笔' : '提醒已关闭',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              _LedgerSwitch(value: enabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerSwitch extends StatelessWidget {
  const _LedgerSwitch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: AppMotion.ease,
      width: 46,
      height: 28,
      decoration: BoxDecoration(
        color: value ? AppColors.mint : const Color(0xFFD9E0DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: AppMotion.ease,
            left: value ? 21 : 3,
            top: 3,
            width: 22,
            height: 22,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x38121A17),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Row(
          children: <Widget>[
            _RowIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerSheet extends StatelessWidget {
  const _LedgerSheet({required this.provider});

  final LedgerProvider provider;

  int _countFor(Ledger ledger) {
    // Matches the prototype: the daily ledger shows this month's count, the
    // travel ledger shows its total count.
    return ledger.id == Ledgers.daily.id
        ? provider.currentMonthCountForLedger(ledger.id)
        : provider.totalCountForLedger(ledger.id);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final ledgerRows = <Widget>[];
    for (var i = 0; i < Ledgers.all.length; i++) {
      final ledger = Ledgers.all[i];
      if (i > 0) ledgerRows.add(const _RowDivider());
      ledgerRows.add(
        _SheetLedgerRow(
          ledger: ledger,
          count: _countFor(ledger),
          selected: provider.selectedLedger.id == ledger.id,
          onTap: () async {
            await provider.selectLedger(ledger.id);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            showAppToast('已切换到「${ledger.name}」');
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x80091812),
            offset: Offset(0, -12),
            blurRadius: 32,
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE4DF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const Text(
            '管理账本',
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '账本用来区分不同场景的开支',
            style: TextStyle(fontSize: 11.5, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          ...ledgerRows,
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: Material(
              color: const Color(0xFFF1F5F1),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLedgerRow extends StatelessWidget {
  const _SheetLedgerRow({
    required this.ledger,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Ledger ledger;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            const _RowIcon(Icons.menu_book_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ledger.name,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count 笔记录',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.mint),
          ],
        ),
      ),
    );
  }
}
