import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/ledger.dart';
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

@immutable
class MonthlyTotal {
  const MonthlyTotal({
    required this.month,
    required this.expenseCents,
    required this.incomeCents,
  });

  final DateTime month;
  final int expenseCents;
  final int incomeCents;
}

/// Single source of truth for the ledger UI. It listens to the Hive box, so
/// writes coming from anywhere refresh every screen automatically.
class LedgerProvider extends ChangeNotifier {
  LedgerProvider(this._box, this._metaBox) {
    _boxListenable = _box.listenable();
    _boxListenable.addListener(_handleStorageChanged);
    _selectedLedger = Ledgers.byId(_metaBox.get(_selectedLedgerKey) as String?);
    _reminderEnabled = _metaBox.get(_reminderKey) as bool? ?? true;
    _lastBackupAt = _parseDate(_metaBox.get(_backupAtKey));
    _reload();
  }

  static const String _selectedLedgerKey = 'selected_ledger';
  static const String _reminderKey = 'reminder_enabled';
  static const String _backupAtKey = 'last_backup_at';
  static const String _backupDataKey = 'backup_json';

  static const int budgetCents = 500000;

  final Box<Record> _box;
  final Box<dynamic> _metaBox;
  late final Listenable _boxListenable;

  List<Record> _records = const <Record>[];
  Ledger _selectedLedger = Ledgers.daily;
  bool _reminderEnabled = true;
  DateTime? _lastBackupAt;
  bool _disposed = false;
  int _sequence = 0;

  Ledger get selectedLedger => _selectedLedger;

  bool get reminderEnabled => _reminderEnabled;

  DateTime? get lastBackupAt => _lastBackupAt;

  List<Record> get allRecords => List<Record>.unmodifiable(_records);

  List<Record> get records {
    return List<Record>.unmodifiable(
      _records.where((record) => record.ledgerId == _selectedLedger.id),
    );
  }

  List<Record> get currentMonthRecords {
    final now = DateTime.now();
    return _records
        .where(
          (record) =>
              record.ledgerId == _selectedLedger.id &&
              Dates.isSameMonth(record.date, now),
        )
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
    return expenseCategoryTotalsFor(currentMonthRecords);
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
    return _sum(recordsForMonth(previous), RecordType.expense);
  }

  int get currentMonthCount => currentMonthRecords.length;

  int get totalCount => records.length;

  bool get isEmpty => records.isEmpty;

  List<Record> recordsForMonth(DateTime month) {
    return _records
        .where(
          (record) =>
              record.ledgerId == _selectedLedger.id &&
              Dates.isSameMonth(record.date, month),
        )
        .toList(growable: false);
  }

  List<Record> recordsForYear(int year) {
    return _records
        .where(
          (record) =>
              record.ledgerId == _selectedLedger.id && record.date.year == year,
        )
        .toList(growable: false);
  }

  int expenseCentsForMonth(DateTime month) {
    return _sum(recordsForMonth(month), RecordType.expense);
  }

  int incomeCentsForMonth(DateTime month) {
    return _sum(recordsForMonth(month), RecordType.income);
  }

  List<MonthlyTotal> monthlyTotals(DateTime endMonth, int count) {
    return <MonthlyTotal>[
      for (var i = count - 1; i >= 0; i--)
        () {
          final month = DateTime(endMonth.year, endMonth.month - i, 1);
          return MonthlyTotal(
            month: month,
            expenseCents: expenseCentsForMonth(month),
            incomeCents: incomeCentsForMonth(month),
          );
        }(),
    ];
  }

  List<CategoryTotal> expenseCategoryTotalsFor(Iterable<Record> records) {
    final totals = <String, int>{};
    for (final record in records) {
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

  int totalCountForLedger(String ledgerId) {
    return _records.where((record) => record.ledgerId == ledgerId).length;
  }

  int currentMonthCountForLedger(String ledgerId) {
    final now = DateTime.now();
    return _records
        .where(
          (record) =>
              record.ledgerId == ledgerId &&
              Dates.isSameMonth(record.date, now),
        )
        .length;
  }

  Future<void> selectLedger(String ledgerId) async {
    final next = Ledgers.byId(ledgerId);
    if (next.id == _selectedLedger.id) return;
    _selectedLedger = next;
    await _metaBox.put(_selectedLedgerKey, next.id);
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    if (_reminderEnabled == enabled) return;
    _reminderEnabled = enabled;
    await _metaBox.put(_reminderKey, enabled);
    notifyListeners();
  }

  /// Writes a JSON snapshot of every record into the local meta box and
  /// remembers the time. It is a real local backup, not just a fake toast.
  Future<void> backupNow() async {
    final now = DateTime.now();
    final snapshot = jsonEncode(
      _records.map((record) => record.toJson()).toList(growable: false),
    );
    await _metaBox.put(_backupDataKey, snapshot);
    await _metaBox.put(_backupAtKey, now.toIso8601String());
    _lastBackupAt = now;
    notifyListeners();
  }

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
      ledgerId: _selectedLedger.id,
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

  static DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
