import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// First pass at the stats tab: real monthly aggregates and a category
/// breakdown. The donut and six-month bar chart are the next UI pass.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final now = DateTime.now();
    final categories = ledger.currentMonthExpenseByCategory;
    final expense = ledger.currentMonthExpenseCents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: <Widget>[
              const Text('统计', style: AppText.screenTitle),
              const Spacer(),
              Text(
                Dates.monthLabel(now),
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                          '本月支出',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Dates.monthShort(now),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Money.formatCents(expense),
                        style: AppText.balanceAmount,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: AppColors.line2),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Stat(
                            label: '本月收入',
                            value: Money.formatCents(
                              ledger.currentMonthIncomeCents,
                            ),
                            color: AppColors.amberInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Stat(
                            label: '本月结余',
                            value: Money.formatCents(
                              ledger.currentMonthBalanceCents,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('支出分类', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              if (categories.isEmpty)
                const _StatsEmpty()
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.list),
                    border: Border.all(color: AppColors.line2),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: <Widget>[
                      for (var i = 0; i < categories.length; i++) ...<Widget>[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.line2,
                          ),
                        _CategoryRow(
                          total: categories[i],
                          monthExpense: expense,
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '数据只保存在本机',
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.total, required this.monthExpense});

  final CategoryTotal total;
  final int monthExpense;

  @override
  Widget build(BuildContext context) {
    final fraction = monthExpense == 0 ? 0.0 : total.cents / monthExpense;
    final percent = '${(fraction * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: total.category.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  total.category.icon,
                  size: 18,
                  color: total.category.foreground,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  total.category.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                percent,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.ink3,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Money.formatCents(total.cents),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: AppColors.mintTint,
              color: total.category.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsEmpty extends StatelessWidget {
  const _StatsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.list),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 28,
            color: AppColors.ink3,
          ),
          SizedBox(height: 8),
          Text(
            '本月还没有支出记录',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
