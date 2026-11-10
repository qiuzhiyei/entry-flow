import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<DateTime?> showStatsMonthPicker(
  BuildContext context, {
  required DateTime selected,
  required int minYear,
  required DateTime maxMonth,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthPickerDialog(
      selected: selected,
      minYear: minYear,
      maxMonth: maxMonth,
    ),
  );
}

Future<int?> showStatsYearPicker(
  BuildContext context, {
  required int selectedYear,
  required int minYear,
  required int maxYear,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _YearPickerDialog(
      selectedYear: selectedYear,
      minYear: minYear,
      maxYear: maxYear,
    ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.selected,
    required this.minYear,
    required this.maxMonth,
  });

  final DateTime selected;
  final int minYear;
  final DateTime maxMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year;
  }

  bool _isFuture(int month) {
    return _year == widget.maxMonth.year && month > widget.maxMonth.month;
  }

  void _pick(int month) {
    if (_isFuture(month)) return;
    Navigator.of(context).pop(DateTime(_year, month));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择月份'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: _year > widget.minYear
                      ? () => setState(() => _year--)
                      : null,
                  tooltip: '上一年',
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year年',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _year < widget.maxMonth.year
                      ? () => setState(() => _year++)
                      : null,
                  tooltip: '下一年',
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
              children: <Widget>[
                for (var month = 1; month <= 12; month++)
                  _PickerCell(
                    label: '$month月',
                    selected:
                        _year == widget.selected.year &&
                        month == widget.selected.month,
                    enabled: !_isFuture(month),
                    onTap: () => _pick(month),
                  ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      actions: <Widget>[
        SizedBox(
          width: 104,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink2,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}

class _YearPickerDialog extends StatelessWidget {
  const _YearPickerDialog({
    required this.selectedYear,
    required this.minYear,
    required this.maxYear,
  });

  final int selectedYear;
  final int minYear;
  final int maxYear;

  @override
  Widget build(BuildContext context) {
    final years = <int>[for (var year = maxYear; year >= minYear; year--) year];

    return AlertDialog(
      title: const Text('选择年份'),
      content: SizedBox(
        width: 300,
        height: 280,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            return _PickerCell(
              label: '$year',
              selected: year == selectedYear,
              onTap: () => Navigator.of(context).pop(year),
            );
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      actions: <Widget>[
        SizedBox(
          width: 104,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink2,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}

class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : (enabled ? AppColors.ink : AppColors.ink3.withValues(alpha: 0.35));

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.mint : AppColors.mintTint,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
