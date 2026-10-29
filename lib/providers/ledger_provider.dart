import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../utils/formatters.dart';

@immutable
class DayGroup {
  const DayGroup({required this.day, required this.records});

  final DateTime day;
  final List<Record> records;

  int get expenseCents => records
      .where((record) => record.type == RecordType.expense)
      .fold(0, (sum, record) => sum + record.amountCents);

  int get incomeCents => records
      .where((record) => record.type == RecordType.income)
      .fold(0, (sum, record) => sum + record.amountCents);
}

@immutable
class CategoryTotal {
  const CategoryTotal({required this.category, required this.cents});

  final LedgerCategory category;
  final int cents;
}

/// Single source of truth for the ledger UI. It listens to the Hive box, so
/// writes coming from anywhere (including future sync/import features) refresh
/// every screen automatically.
class LedgerProvider extends ChangeNotifier {
  LedgerProvider(this._box) {
    _boxListenable = _box.listenable();
    _boxListenable.addListener(_handleStorageChanged);
    _reload();
  }

  final Box<Record> _box;
  late final Listenable _boxListenable;

  List<Record> _records = const <Record>[];
  bool _disposed = false;
  int _sequence = 0;

  List<Record> get records => List<Record>.unmodifiable(_records);

  List<Record> get currentMonthRecords {
    final now = DateTime.now();
    return _records
        .where((record) => Dates.isSameMonth(record.date, now))
        .toList(growable: false);
  }

  List<DayGroup> get currentMonthGroups {
    final grouped = <DateTime, List<Record>>{};
    for (final record in currentMonthRecords) {
      final day = Dates.dayOnly(record.date);
      grouped.putIfAbsent(day, () => <Record>[]).add(record);
    }
    return <DayGroup>[
      for (final entry in grouped.entries)
        DayGroup(
          day: entry.key,
          records: List<Record>.unmodifiable(entry.value),
        ),
    ];
  }

  List<CategoryTotal> get currentMonthExpenseByCategory {
    final totals = <String, int>{};
    for (final record in currentMonthRecords) {
      if (record.type != RecordType.expense) continue;
      totals.update(
        record.categoryId,
        (value) => value + record.amountCents,
        ifAbsent: () => record.amountCents,
      );
    }
    final rows = totals.entries
        .map(
          (entry) => CategoryTotal(
            category: LedgerCategories.byId(entry.key),
            cents: entry.value,
          ),
        )
        .toList(growable: false);
    rows.sort((a, b) => b.cents.compareTo(a.cents));
    return rows;
  }

  int get currentMonthExpenseCents =>
      _sum(currentMonthRecords, RecordType.expense);

  int get currentMonthIncomeCents =>
      _sum(currentMonthRecords, RecordType.income);

  int get currentMonthBalanceCents =>
      currentMonthIncomeCents - currentMonthExpenseCents;

  int get previousMonthExpenseCents {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    final records = _records.where(
      (record) => Dates.isSameMonth(record.date, previous),
    );
    return _sum(records, RecordType.expense);
  }

  int get currentMonthCount => currentMonthRecords.length;

  int get totalCount => _records.length;

  bool get isEmpty => _records.isEmpty;

  @override
  void dispose() {
    _disposed = true;
    _boxListenable.removeListener(_handleStorageChanged);
    super.dispose();
  }

  Future<void> addRecord({
    required int amountCents,
    required RecordType type,
    required String categoryId,
    required DateTime date,
    String note = '',
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', '必须大于 0');
    }
    final now = DateTime.now();
    final record = Record(
      id: _newId(now),
      amountCents: amountCents,
      type: type,
      categoryId: categoryId,
      date: date,
      note: note.trim(),
      createdAt: now,
    );
    await _box.put(record.id, record);
    _reload();
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
    _reload();
  }

  Future<void> clearAll() async {
    await _box.clear();
    _reload();
  }

  void _handleStorageChanged() => _reload();

  void _reload() {
    if (_disposed) return;
    final items = _box.values.toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    _records = items;
    notifyListeners();
  }

  int _sum(Iterable<Record> records, RecordType type) {
    return records
        .where((record) => record.type == type)
        .fold(0, (sum, record) => sum + record.amountCents);
  }

  String _newId(DateTime now) {
    final timestamp = now.microsecondsSinceEpoch.toRadixString(36);
    return 'r$timestamp${(_sequence++).toRadixString(36)}';
  }
}
