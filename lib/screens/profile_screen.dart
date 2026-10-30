import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../models/ledger.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/clear_data_flow.dart';
import '../widgets/data_backup_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _switchLedger(BuildContext context) async {
    final provider = context.read<LedgerProvider>();
    final current = provider.selectedLedger;
    final next = Ledgers.all.firstWhere(
      (ledger) => ledger.id != current.id,
      orElse: () => current,
    );
    if (next.id == current.id) return;

    try {
      await provider.selectLedger(next.id);
      if (!context.mounted) return;
      showAppToast('已切换到「${next.name}」');
    } catch (_) {
      if (!context.mounted) return;
      showAppToast('账本切换失败，请重试');
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
    final otherLedger = Ledgers.all.firstWhere(
      (item) => item.id != ledger.selectedLedger.id,
      orElse: () => ledger.selectedLedger,
    );

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
              _SectionHead('账本'),
              _ListCard(
                children: <Widget>[
                  _LedgerRow(
                    ledger: ledger.selectedLedger,
                    subtitle: otherLedger.id == ledger.selectedLedger.id
                        ? '当前账本'
                        : '点按切换到「${otherLedger.name}」',
                    onTap: () => _switchLedger(context),
                  ),
                ],
              ),
              _SectionHead('通用设置'),
              _ListCard(
                children: <Widget>[
                  _SettingRow(
                    icon: Icons.file_download_outlined,
                    title: '数据备份',
                    subtitle: Dates.backupLabel(ledger.lastBackupAt, now: now),
                    onTap: () => showDataBackupSheet(context),
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.delete_outline_rounded,
                    title: '清理数据',
                    subtitle: '清空全部账目，需两次确认',
                    danger: true,
                    onTap: () => showClearDataFlow(context),
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
  const _RowIcon(this.icon, {this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFBEAE8) : AppColors.mintTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        size: 18,
        color: danger ? AppColors.danger : AppColors.mintInk,
      ),
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
              Icons.swap_horiz_rounded,
              size: 20,
              color: AppColors.ink3,
            ),
          ],
        ),
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
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Row(
          children: <Widget>[
            _RowIcon(icon, danger: danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: danger ? AppColors.danger : AppColors.ink,
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
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: danger
                  ? AppColors.danger.withValues(alpha: 0.55)
                  : AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}
