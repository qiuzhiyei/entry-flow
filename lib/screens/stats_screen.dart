import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_charts.dart';

enum _StatsRange { month, year }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsRange _range = _StatsRange.month;
  late DateTime _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _year = now.year;
  }

  DateTime get _now => DateTime.now();
  DateTime get _minMonth => DateTime(_now.year, 1);
  DateTime get _maxMonth => DateTime(_now.year, _now.month);

  void _setRange(_StatsRange range) {
    if (_range == range) return;
    setState(() {
      _range = range;
      if (range == _StatsRange.year) _year = _now.year;
    });
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isBefore(_minMonth) || next.isAfter(_maxMonth)) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final isYear = _range == _StatsRange.year;
    final records = isYear
        ? ledger.recordsForYear(_year)
        : ledger.recordsForMonth(_month);
    final slices = _buildSlices(ledger.expenseCategoryTotalsFor(records));
    final totalExpense = slices.fold<int>(0, (sum, slice) => sum + slice.cents);
    final visibleSlices = slices.where((slice) => slice.cents > 0).toList()
      ..sort((a, b) => b.cents.compareTo(a.cents));
    final series = isYear
        ? ledger.monthlyTotals(DateTime(_year, 12, 1), 12)
        : ledger.monthlyTotals(_month, 6);
    final yearStats = isYear ? _yearStats(series) : null;
    final current = series.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: <Widget>[
              const Text('统计', style: AppText.screenTitle),
              const Spacer(),
              _RangeSegment(range: _range, onChanged: _setRange),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: _MonthSwitch(
                  month: _month,
                  year: _year,
                  isYear: isYear,
                  canGoPrevious: _month.isAfter(_minMonth),
                  canGoNext: _month.isBefore(_maxMonth),
                  onPrevious: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
              ),
              _DonutCard(
                slices: slices,
                visibleSlices: visibleSlices,
                totalCents: totalExpense,
                subtitle: isYear ? '全年' : Dates.monthShort(_month),
                emptyText: isYear ? '这一年还没有支出记录' : '这个月还没有支出记录',
                yearStats: yearStats,
              ),
              const SizedBox(height: 14),
              _BarCard(
                title: isYear ? '全年 12 个月收支' : '近 6 个月收支',
                series: series,
                isYear: isYear,
                expenseCents: isYear
                    ? series.fold<int>(
                        0,
                        (sum, item) => sum + item.expenseCents,
                      )
                    : current.expenseCents,
                incomeCents: isYear
                    ? series.fold<int>(0, (sum, item) => sum + item.incomeCents)
                    : current.incomeCents,
                currentMonth: current.month,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DonutSlice> _buildSlices(List<CategoryTotal> totals) {
    final values = List<int>.filled(_sliceDefinitions.length, 0);
    for (final total in totals) {
      var index = _sliceDefinitions.indexWhere(
        (definition) => definition.categories.contains(total.category.id),
      );
      if (index < 0) index = _sliceDefinitions.length - 1;
      values[index] += total.cents;
    }
    return <DonutSlice>[
      for (var i = 0; i < _sliceDefinitions.length; i++)
        DonutSlice(
          name: _sliceDefinitions[i].name,
          color: _sliceDefinitions[i].color,
          cents: values[i],
        ),
    ];
  }

  _YearStats? _yearStats(List<MonthlyTotal> series) {
    final active = series
        .where((item) => item.expenseCents > 0)
        .toList(growable: false);
    if (active.isEmpty) return null;
    final total = active.fold<int>(0, (sum, item) => sum + item.expenseCents);
    var peak = active.first;
    for (final item in active) {
      if (item.expenseCents > peak.expenseCents) peak = item;
    }
    return _YearStats(
      averageCents: (total / active.length).round(),
      peakMonth: peak.month,
      peakCents: peak.expenseCents,
    );
  }
}

class _RangeSegment extends StatelessWidget {
  const _RangeSegment({required this.range, required this.onChanged});

  final _StatsRange range;
  final ValueChanged<_StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.segmentBg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _RangeButton(
            label: '按月',
            selected: range == _StatsRange.month,
            onTap: () => onChanged(_StatsRange.month),
          ),
          _RangeButton(
            label: '按年',
            selected: range == _StatsRange.year,
            onTap: () => onChanged(_StatsRange.year),
          ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: AppMotion.ease,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x2112211B),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.ink : AppColors.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSwitch extends StatelessWidget {
  const _MonthSwitch({
    required this.month,
    required this.year,
    required this.isYear,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final int year;
  final bool isYear;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isYear ? 48 : 54,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.soft),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: isYear
          ? Center(
              child: Text(
                '$year年',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.14,
                  color: AppColors.ink,
                ),
              ),
            )
          : Row(
              children: <Widget>[
                _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: canGoPrevious ? onPrevious : null,
                  semanticsLabel: '上一个月',
                ),
                Expanded(
                  child: Text(
                    Dates.monthLabel(month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: canGoNext ? onNext : null,
                  semanticsLabel: '下一个月',
                ),
              ],
            ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20),
          color: AppColors.ink2,
          disabledColor: AppColors.ink2.withValues(alpha: 0.3),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({
    required this.slices,
    required this.visibleSlices,
    required this.totalCents,
    required this.subtitle,
    required this.emptyText,
    required this.yearStats,
  });

  final List<DonutSlice> slices;
  final List<DonutSlice> visibleSlices;
  final int totalCents;
  final String subtitle;
  final String emptyText;
  final _YearStats? yearStats;

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
                '支出构成',
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
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: DonutChart(slices: slices, totalCents: totalCents),
          ),
          const SizedBox(height: 12),
          if (visibleSlices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyText,
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
              ),
            )
          else
            for (final slice in visibleSlices)
              _LegendRow(slice: slice, totalCents: totalCents),
          if (yearStats != null) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.line2),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                Expanded(
                  child: _YearStat(
                    label: '月均支出',
                    value: Money.formatShortCents(yearStats!.averageCents),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _YearStat(
                    label: '支出最高月',
                    value:
                        '${yearStats!.peakMonth.month}月 · '
                        '${Money.formatShortCents(yearStats!.peakCents)}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.totalCents});

  final DonutSlice slice;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final percent = totalCents == 0 ? 0.0 : slice.cents / totalCents * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: slice.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slice.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.ink3,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(
              Money.formatCents(slice.cents),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearStat extends StatelessWidget {
  const _YearStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.14,
            color: AppColors.ink,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({
    required this.title,
    required this.series,
    required this.isYear,
    required this.expenseCents,
    required this.incomeCents,
    required this.currentMonth,
  });

  final String title;
  final List<MonthlyTotal> series;
  final bool isYear;
  final int expenseCents;
  final int incomeCents;
  final DateTime currentMonth;

  @override
  Widget build(BuildContext context) {
    final balance = incomeCents - expenseCents;
    const baseStyle = TextStyle(
      fontSize: 11.5,
      height: 1.55,
      color: AppColors.ink3,
      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    );
    final boldStyle = baseStyle.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    );
    final summarySpans = <TextSpan>[
      if (isYear)
        const TextSpan(text: '全年支出 ')
      else
        TextSpan(text: '${currentMonth.month}月 支出 '),
      TextSpan(text: Money.formatCents(expenseCents), style: boldStyle),
      const TextSpan(text: ' · 收入 '),
      TextSpan(text: Money.formatCents(incomeCents), style: boldStyle),
      if (isYear) ...<TextSpan>[
        const TextSpan(text: ' · 结余 '),
        TextSpan(text: Money.formatCents(balance), style: boldStyle),
      ],
    ];

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.145,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const _ChartLegend(color: AppColors.mint, label: '支出'),
              const SizedBox(width: 13),
              const _ChartLegend(color: AppColors.amber, label: '收入'),
            ],
          ),
          const SizedBox(height: 12),
          MonthlyBarChart(data: series),
          const SizedBox(height: 10),
          Text.rich(TextSpan(style: baseStyle, children: summarySpans)),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }
}

class _YearStats {
  const _YearStats({
    required this.averageCents,
    required this.peakMonth,
    required this.peakCents,
  });

  final int averageCents;
  final DateTime peakMonth;
  final int peakCents;
}

class _SliceDefinition {
  const _SliceDefinition(this.name, this.categories, this.color);

  final String name;
  final List<String> categories;
  final Color color;
}

const List<_SliceDefinition> _sliceDefinitions = <_SliceDefinition>[
  _SliceDefinition('居家', <String>['home'], Color(0xFF1BAF7A)),
  _SliceDefinition('购物', <String>['shopping'], Color(0xFFEB6834)),
  _SliceDefinition('餐饮', <String>['food'], Color(0xFF2A78D6)),
  _SliceDefinition('红包', <String>['packet'], Color(0xFFE34948)),
  _SliceDefinition('交通', <String>['transport'], Color(0xFFEDA100)),
  _SliceDefinition('娱乐', <String>['fun'], Color(0xFFE87BA4)),
  _SliceDefinition('还款', <String>['repay'], Color(0xFF008300)),
  _SliceDefinition('其他', <String>[
    'medical',
    'study',
    'other',
    'otherin',
  ], Color(0xFF4A3AA7)),
];
