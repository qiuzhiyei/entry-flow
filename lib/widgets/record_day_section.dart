import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// A day header plus its transaction card, shared by Home and Stats.
class RecordDaySection extends StatelessWidget {
  const RecordDaySection({super.key, required this.group});

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
                  RecordTile(record: group.records[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One transaction row with category, note, and semantic signed amount.
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record});

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
                  ? AppColors.income
                  : AppColors.expense,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
