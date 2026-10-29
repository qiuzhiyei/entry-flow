import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// First pass at the profile tab. Budget and the prototype's settings rows
/// belong to the next UI pass; this screen already owns real data actions.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清空所有记录？'),
          content: const Text('所有账目都会从这台设备上删除，且无法恢复。'),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink2,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<LedgerProvider>().clearAll();
    if (!context.mounted) return;
    showAppSnackBar('已清空所有记录');
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();

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
              _UserCard(),
              const SizedBox(height: 14),
              _BudgetCard(),
              const SizedBox(height: 22),
              const Text('数据', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.list),
                  border: Border.all(color: AppColors.line2),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: <Widget>[
                    _InfoRow(
                      icon: Icons.storage_rounded,
                      title: '记录总数',
                      subtitle: '全部保存在这台设备',
                      trailing: '${ledger.totalCount} 笔',
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.line2,
                    ),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      title: '本月记录',
                      subtitle: '仅统计当前月份',
                      trailing: '${ledger.currentMonthCount} 笔',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('通用设置', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.list),
                  border: Border.all(color: AppColors.line2),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: <Widget>[
                    const _InfoRow(
                      icon: Icons.info_outline_rounded,
                      title: '关于记账本',
                      subtitle: '本地运行 · 无需登录',
                      trailing: 'v1.0.0',
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.line2,
                    ),
                    _DangerRow(onTap: () => _confirmClear(context)),
                  ],
                ),
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
              '记',
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
                  '本地记账本',
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
                  '无需登录 · 数据只保存在本机',
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
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 14, color: AppColors.mintInk),
                SizedBox(width: 4),
                Text(
                  '本地',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintInk,
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
  static const int _budgetCents = 500000;

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final used = ledger.currentMonthExpenseCents;
    final fraction = (used / _budgetCents).clamp(0.0, 1.0).toDouble();
    final over = used > _budgetCents;
    final now = DateTime.now();

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
              const Text('本月预算', style: AppText.sectionTitle),
              const Spacer(),
              Text(
                Dates.monthShort(now),
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
                Money.formatShortCents(used),
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
                '/ ${Money.formatShortCents(_budgetCents)}',
                style: const TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: AppColors.mintTint,
              color: over ? AppColors.danger : AppColors.mint,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                over ? '已超支' : '已用 ${(used / _budgetCents * 100).round()}%',
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
              const Spacer(),
              Text(
                over
                    ? '预算 ${Money.formatShortCents(_budgetCents)}'
                    : '剩余 ${Money.formatShortCents(_budgetCents - used)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.mintTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.mintInk),
          ),
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
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '清空所有记录',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
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
