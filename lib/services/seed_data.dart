import 'package:hive/hive.dart';

import '../models/record.dart';

/// Demo entries are written only on the very first launch. Set this to `false`
/// for a clean ledger. Clearing every record never re-seeds them.
const bool kSeedDemoData = true;

abstract final class SeedData {
  static const String _seededKey = 'demo_seeded';
  static const String _versionKey = 'demo_version';
  static const int _version = 2;

  static const String _dailyLedger = 'daily';
  static const String _travelLedger = 'travel';

  static Future<void> seedIfNeeded(
    Box<Record> box,
    Box<dynamic> metaBox,
  ) async {
    if (!kSeedDemoData) return;

    final seeded = metaBox.get(_seededKey) == true;
    if (seeded) {
      await _upgradeDemoData(box, metaBox);
      return;
    }

    if (box.isNotEmpty) {
      await metaBox.put(_seededKey, true);
      await metaBox.put(_versionKey, _version);
      return;
    }

    final now = DateTime.now();
    final records = <Record>[];

    void add(
      int monthsAgo,
      String type,
      String categoryId,
      num amount,
      String note,
      int day,
      String time, {
      String ledgerId = _dailyLedger,
    }) {
      final parts = time.split(':');
      final date = _dateFor(
        now,
        monthsAgo,
        day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      records.add(
        Record(
          id: 'demo-${now.microsecondsSinceEpoch.toRadixString(36)}-${records.length}',
          amountCents: (amount * 100).round(),
          type: type == 'income' ? RecordType.income : RecordType.expense,
          categoryId: categoryId,
          date: date,
          note: note,
          createdAt: date,
          ledgerId: ledgerId,
        ),
      );
    }

    // ----- current month: the prototype's October dataset -----
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

    // ----- previous two months -----
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

    // ----- earlier months, so the year chart is complete -----
    records.addAll(_buildHistoricalRecords(now));
    records.addAll(_buildTravelRecords(now));

    await box.addAll(records);
    await metaBox.put(_seededKey, true);
    await metaBox.put(_versionKey, _version);
  }

  /// Older demo installs already have the October/September/... records.
  /// Version 2 adds the earlier months and the travel ledger without touching
  /// the user's own records.
  static Future<void> _upgradeDemoData(
    Box<Record> box,
    Box<dynamic> metaBox,
  ) async {
    final version = metaBox.get(_versionKey) as int? ?? 1;
    if (version >= _version) return;

    final hasDemoRecords = box.values.any(
      (record) => record.id.startsWith('demo-'),
    );
    if (hasDemoRecords) {
      final now = DateTime.now();
      final existingIds = box.keys.cast<String>().toSet();
      final additions = <Record>[
        ..._buildHistoricalRecords(now),
        ..._buildTravelRecords(now),
      ].where((record) => !existingIds.contains(record.id)).toList();
      if (additions.isNotEmpty) await box.addAll(additions);
    }

    await metaBox.put(_versionKey, _version);
  }

  static List<Record> _buildHistoricalRecords(DateTime now) {
    final records = <Record>[];
    var index = 0;

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
      final date = _dateFor(
        now,
        monthsAgo,
        day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      records.add(
        Record(
          id: 'demo-history-${now.microsecondsSinceEpoch.toRadixString(36)}-${index++}',
          amountCents: (amount * 100).round(),
          type: type == 'income' ? RecordType.income : RecordType.expense,
          categoryId: categoryId,
          date: date,
          note: note,
          createdAt: date,
          ledgerId: _dailyLedger,
        ),
      );
    }

    // June (4 months ago)
    add(4, 'expense', 'home', 2200, '六月房租', 1, '09:00');
    add(4, 'expense', 'food', 700, '六月餐饮', 15, '18:00');
    add(4, 'expense', 'shopping', 420, '日用品', 8, '20:00');
    add(4, 'expense', 'transport', 190, '六月交通', 24, '08:10');
    add(4, 'income', 'salary', 8200, '六月工资', 10, '10:00');

    // May (5 months ago)
    add(5, 'expense', 'home', 2200, '五月房租', 1, '09:00');
    add(5, 'expense', 'food', 640, '五月餐饮', 13, '18:20');
    add(5, 'expense', 'shopping', 300, '小家电', 7, '14:00');
    add(5, 'expense', 'transport', 170, '五月交通', 27, '08:00');
    add(5, 'expense', 'fun', 150, '桌游局', 23, '20:30');
    add(5, 'income', 'salary', 8200, '五月工资', 10, '10:00');
    add(5, 'income', 'parttime', 600, '翻译稿费', 19, '16:00');

    // April (6 months ago)
    add(6, 'expense', 'home', 2200, '四月房租', 1, '09:00');
    add(6, 'expense', 'food', 680, '四月餐饮', 13, '18:20');
    add(6, 'expense', 'shopping', 890, '换了台显示器', 8, '20:00');
    add(6, 'expense', 'fun', 240, '周末展览', 19, '14:30');
    add(6, 'expense', 'transport', 160, '四月交通', 27, '08:10');
    add(6, 'income', 'salary', 8200, '四月工资', 10, '10:00');
    add(6, 'income', 'invest', 88.6, '理财收益', 28, '09:00');

    // March (7 months ago)
    add(7, 'expense', 'home', 2200, '三月房租', 1, '09:00');
    add(7, 'expense', 'food', 720, '三月餐饮', 15, '18:40');
    add(7, 'expense', 'shopping', 260, '换季收纳', 9, '14:00');
    add(7, 'expense', 'medical', 280, '春季体检', 6, '09:30');
    add(7, 'expense', 'study', 199, '设计课程', 18, '21:00');
    add(7, 'expense', 'transport', 150, '三月交通', 24, '08:15');
    add(7, 'income', 'salary', 8200, '三月工资', 10, '10:00');
    add(7, 'income', 'parttime', 400, '海报设计稿费', 26, '15:00');

    // February (8 months ago)
    add(8, 'expense', 'home', 2200, '二月房租', 1, '09:00');
    add(8, 'expense', 'shopping', 480, '年货采购', 10, '15:20');
    add(8, 'expense', 'food', 760, '春节聚餐', 14, '18:00');
    add(8, 'expense', 'transport', 320, '回家高铁票', 16, '09:10');
    add(8, 'income', 'salary', 8200, '二月工资', 10, '10:00');
    add(8, 'income', 'redpacket', 1200, '春节红包', 17, '20:00');

    // January (9 months ago)
    add(9, 'expense', 'home', 2200, '一月房租', 1, '09:00');
    add(9, 'expense', 'food', 690, '一月餐饮', 12, '18:30');
    add(9, 'expense', 'shopping', 350, '冬季日用品', 8, '16:00');
    add(9, 'expense', 'transport', 145, '一月交通', 22, '08:20');
    add(9, 'income', 'salary', 8200, '一月工资', 10, '10:00');
    add(9, 'income', 'bonus', 8000, '年终奖', 20, '10:00');

    return records;
  }

  static List<Record> _buildTravelRecords(DateTime now) {
    const notes = <String>[
      '高铁票',
      '民宿住宿',
      '景点门票',
      '旅行餐饮',
      '打车',
      '纪念品',
      '咖啡',
      '租车',
    ];
    const categories = <String>[
      'transport',
      'home',
      'fun',
      'food',
      'transport',
      'shopping',
      'food',
      'transport',
    ];

    return <Record>[
      for (var i = 0; i < 32; i++)
        () {
          final monthsAgo = i < 4 ? 0 : 1 + ((i - 4) % 6);
          final day = 2 + ((i * 5) % 24);
          final date = _dateFor(
            now,
            monthsAgo,
            day,
            9 + (i % 10),
            (i * 7) % 60,
          );
          return Record(
            id: 'demo-travel-${now.microsecondsSinceEpoch.toRadixString(36)}-$i',
            amountCents: (48 + ((i * 73) % 520)) * 100,
            type: RecordType.expense,
            categoryId: categories[i % categories.length],
            date: date,
            note: notes[i % notes.length],
            createdAt: date,
            ledgerId: _travelLedger,
          );
        }(),
    ];
  }

  static DateTime _dateFor(
    DateTime now,
    int monthsAgo,
    int day,
    int hour,
    int minute,
  ) {
    final first = DateTime(now.year, now.month - monthsAgo, 1);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    var dayOfMonth = day < 1 ? 1 : (day > lastDay ? lastDay : day);
    if (monthsAgo == 0 && dayOfMonth > now.day) {
      dayOfMonth = now.day;
    }
    return DateTime(first.year, first.month, dayOfMonth, hour, minute);
  }
}
