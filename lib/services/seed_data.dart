import 'package:hive/hive.dart';

import '../models/record.dart';

/// Demo entries are written only on the very first launch, so the UI has real
/// content to render during development. Set this to `false` for an empty
/// ledger, or use "清空所有记录" in the profile screen.
const bool kSeedDemoData = true;

abstract final class SeedData {
  static const String _seededKey = 'demo_seeded';

  static Future<void> seedIfNeeded(
    Box<Record> box,
    Box<dynamic> metaBox,
  ) async {
    if (!kSeedDemoData) return;

    // The flag survives clearing the ledger, so deleting every record never
    // brings the demo entries back.
    if (metaBox.get(_seededKey) == true) return;
    if (box.isNotEmpty) {
      await metaBox.put(_seededKey, true);
      return;
    }

    final now = DateTime.now();
    final records = <Record>[];
    var index = 0;

    DateTime dateFor(int monthsAgo, int day, int hour, int minute) {
      final first = DateTime(now.year, now.month - monthsAgo, 1);
      final lastDay = DateTime(first.year, first.month + 1, 0).day;
      var dayOfMonth = day < 1 ? 1 : (day > lastDay ? lastDay : day);
      if (monthsAgo == 0 && dayOfMonth > now.day) {
        dayOfMonth = now.day;
      }
      return DateTime(first.year, first.month, dayOfMonth, hour, minute);
    }

    void add(
      int monthsAgo,
      String type,
      String categoryId,
      num amount,
      String note,
      int day,
      String time,
    ) {
      final parts = time.split(':');
      final date = dateFor(
        monthsAgo,
        day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      records.add(
        Record(
          id: 'demo-${now.microsecondsSinceEpoch.toRadixString(36)}-${index++}',
          amountCents: (amount * 100).round(),
          type: type == 'income' ? RecordType.income : RecordType.expense,
          categoryId: categoryId,
          date: date,
          note: note,
          createdAt: date,
        ),
      );
    }

    // ----- current month (mirrors the prototype's October dataset) -----
    add(0, 'expense', 'food', 28, '楼下咖啡', 29, '08:12');
    add(0, 'expense', 'transport', 6, '地铁 2 号线', 29, '08:40');
    add(0, 'expense', 'food', 42.5, '公司楼下简餐', 29, '12:26');
    add(0, 'expense', 'shopping', 129, '洗衣液和收纳盒', 28, '19:05');
    add(0, 'expense', 'food', 86, '和朋友吃火锅', 28, '12:10');
    add(0, 'expense', 'transport', 24, '打车回家', 27, '22:15');
    add(0, 'expense', 'fun', 68, '电影票两张', 27, '15:30');
    add(0, 'expense', 'home', 199, '换季被套', 26, '14:20');
    add(0, 'expense', 'transport', 6, '地铁 2 号线', 26, '08:35');
    add(0, 'expense', 'food', 35, '早餐和午餐', 26, '12:00');
    add(0, 'expense', 'shopping', 302, '超市采购', 25, '17:42');
    add(0, 'expense', 'study', 59, '一本小说', 24, '20:10');
    add(0, 'expense', 'medical', 38.5, '感冒药', 22, '10:05');
    add(0, 'income', 'parttime', 800, '设计外包尾款', 21, '15:00');
    add(0, 'expense', 'shopping', 268, '秋季外套', 20, '16:40');
    add(0, 'expense', 'food', 168, '周末下午茶', 19, '16:20');
    add(0, 'expense', 'fun', 45, '音乐会员', 18, '09:00');
    add(0, 'expense', 'repay', 600, '信用卡账单', 16, '20:30');
    add(0, 'income', 'invest', 126.4, '基金分红', 15, '09:00');
    add(0, 'expense', 'packet', 200, '同事婚礼随礼', 11, '12:40');
    add(0, 'expense', 'food', 156, '周末聚餐', 12, '18:30');
    add(0, 'income', 'salary', 8200, '本月工资', 10, '10:00');
    add(0, 'income', 'redpacket', 200, '朋友生日回礼', 8, '21:10');
    add(0, 'expense', 'transport', 100, '地铁月卡', 3, '07:50');
    add(0, 'expense', 'home', 2200, '本月房租', 1, '09:00');

    // ----- previous months, used for the month-over-month delta -----
    add(1, 'expense', 'home', 2200, '上月房租', 1, '09:00');
    add(1, 'expense', 'food', 860, '月中聚餐与外卖', 12, '19:20');
    add(1, 'expense', 'shopping', 640, '家居小物', 18, '15:10');
    add(1, 'expense', 'fun', 180, '演出门票', 20, '20:00');
    add(1, 'expense', 'transport', 210, '打车与地铁', 25, '08:20');
    add(1, 'income', 'salary', 8200, '上月工资', 10, '10:00');
    add(1, 'income', 'parttime', 500, '插画稿费', 22, '14:00');

    add(2, 'expense', 'home', 2200, '两月前房租', 1, '09:00');
    add(2, 'expense', 'food', 920, '餐饮', 14, '18:40');
    add(2, 'expense', 'shopping', 380, '换季衣物', 9, '16:00');
    add(2, 'expense', 'transport', 260, '交通', 26, '08:30');
    add(2, 'expense', 'study', 240, '线上课程', 17, '21:00');
    add(2, 'income', 'salary', 8200, '工资', 10, '10:00');

    add(3, 'expense', 'home', 2200, '三月前房租', 1, '09:00');
    add(3, 'expense', 'food', 780, '餐饮', 16, '19:00');
    add(3, 'expense', 'shopping', 520, '夏季用品', 11, '15:30');
    add(3, 'expense', 'fun', 320, '周末露营', 19, '11:00');
    add(3, 'expense', 'medical', 160, '体检', 6, '09:30');
    add(3, 'income', 'salary', 8200, '工资', 10, '10:00');
    add(3, 'income', 'bonus', 1200, '季度奖金', 15, '10:00');

    await box.addAll(records);
    await metaBox.put(_seededKey, true);
  }
}
