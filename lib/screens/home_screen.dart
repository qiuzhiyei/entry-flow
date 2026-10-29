import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenStats});

  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final groups = ledger.currentMonthGroups;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _HomeHeader(now: now, ledgerName: ledger.selectedLedger.name),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              // The prototype insets the balance card 20px more than the
              // rest of the scroll content.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BalanceCard(ledger: ledger),
              ),
              _SectionHead(onTap: onOpenStats),
              if (groups.isEmpty)
                const _HomeEmptyState()
              else
                ...groups.map((group) => _DaySection(group: group)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.now, required this.ledgerName});

  final DateTime now;
  final String ledgerName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$ledgerName · ${Dates.cnDate(now)} ${Dates.weekday(now)}',
            style: AppText.eyebrow,
          ),
          const SizedBox(height: 3),
          Text(Dates.greeting(now), style: AppText.greeting),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.ledger});

  final LedgerProvider ledger;

  @override
  Widget build(BuildContext context) {
    final expense = ledger.currentMonthExpenseCents;
    final income = ledger.currentMonthIncomeCents;
    final balance = ledger.currentMonthBalanceCents;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('本月支出', style: AppText.balanceLabel),
              const Spacer(),
              _DeltaBadge(
                expense: expense,
                previousExpense: ledger.previousMonthExpenseCents,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Money.formatCents(expense),
                style: AppText.balanceAmount,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.balanceDivider),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              Expanded(
                child: _BalanceStat(
                  label: '本月收入',
                  value: Money.formatCents(income),
                  valueColor: AppColors.amberInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceStat(
                  label: '本月结余',
                  value: Money.formatCents(balance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.balanceInk,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.balanceKey),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppText.balanceValue.copyWith(color: valueColor),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.expense, required this.previousExpense});

  final int expense;
  final int previousExpense;

  @override
  Widget build(BuildContext context) {
    final hasPrevious = previousExpense > 0;
    String label = '暂无上月数据';
    IconData? icon;

    if (hasPrevious) {
      final percent = (expense - previousExpense).abs() / previousExpense * 100;
      final decreased = expense <= previousExpense;
      label = '较上月${decreased ? '减少' : '增加'} ${percent.toStringAsFixed(1)}%';
      icon = decreased
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
    }

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.deltaPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: AppColors.mintInk),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w600,
              color: AppColors.mintInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: <Widget>[
          const Text('最近交易', style: AppText.sectionTitle),
          const Spacer(),
          Semantics(
            button: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Text('查看统计', style: AppText.link),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.mintInk,
                      ),
                    ],
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

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final totals = <String>[];
    if (group.expenseCents > 0) {
      totals.add('支出 ${Money.formatCents(group.expenseCents)}');
    }
    if (group.incomeCents > 0) {
      totals.add('收入 ${Money.formatCents(group.incomeCents)}');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 7),
            child: Row(
              children: <Widget>[
                Text(Dates.dayLabel(group.day), style: AppText.dayLabel),
                const Spacer(),
                if (totals.isNotEmpty)
                  Text(
                    totals.join(' · '),
                    style: AppText.dayTotal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.list),
              border: Border.all(color: AppColors.line2),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < group.records.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.line2,
                    ),
                  _RecordRow(record: group.records[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final Record record;

  @override
  Widget build(BuildContext context) {
    final category = LedgerCategories.byId(
      record.categoryId,
      type: record.type,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: category.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, size: 22, color: category.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  category.name,
                  style: AppText.recordName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  record.note.isEmpty ? '无备注' : record.note,
                  style: AppText.recordNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Money.signedCents(record.amountCents, record.type),
            style: AppText.recordAmount.copyWith(
              color: record.type == RecordType.income
                  ? AppColors.amberInk
                  : AppColors.ink,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CustomPaint(
        foregroundPainter: const _DashedRoundedBorder(
          color: AppColors.line,
          radius: AppRadii.list,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.list),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mintTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '这个月还没有记录',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '点下面的「记一笔」，从第一笔开始',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.ink3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorder extends CustomPainter {
  const _DashedRoundedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dash = 4.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorder oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
