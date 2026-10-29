import 'dart:io';

import 'package:entry_flow/models/record.dart';
import 'package:entry_flow/providers/ledger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Record> box;
  late Box<dynamic> meta;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    box = await Hive.openBox<Record>('records');
    meta = await Hive.openBox<dynamic>('meta');
  });

  setUp(() async {
    await box.clear();
    await meta.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('adding a record updates totals and day groups', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.addRecord(
      amountCents: 1250,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime.now(),
      note: '午饭',
    );

    expect(provider.records, hasLength(1));
    expect(provider.currentMonthExpenseCents, 1250);
    expect(provider.currentMonthIncomeCents, 0);
    expect(provider.currentMonthBalanceCents, -1250);
    expect(provider.currentMonthGroups, hasLength(1));

    final group = provider.currentMonthGroups.single;
    expect(group.records.single.note, '午饭');
    expect(group.expenseCents, 1250);
  });

  test('month-over-month comparison reads the previous month', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 15, 12);

    await provider.addRecord(
      amountCents: 1000,
      type: RecordType.expense,
      categoryId: 'food',
      date: previousMonth,
    );
    await provider.addRecord(
      amountCents: 2500,
      type: RecordType.expense,
      categoryId: 'food',
      date: now,
    );

    expect(provider.currentMonthExpenseCents, 2500);
    expect(provider.previousMonthExpenseCents, 1000);
  });

  test('income and expense are aggregated separately', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.addRecord(
      amountCents: 820000,
      type: RecordType.income,
      categoryId: 'salary',
      date: DateTime.now(),
    );
    await provider.addRecord(
      amountCents: 20000,
      type: RecordType.expense,
      categoryId: 'home',
      date: DateTime.now(),
    );

    expect(provider.currentMonthIncomeCents, 820000);
    expect(provider.currentMonthExpenseCents, 20000);
    expect(provider.currentMonthBalanceCents, 800000);
    expect(provider.currentMonthExpenseByCategory.single.cents, 20000);
  });

  test('clearAll removes every record and notifies listeners', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.addRecord(
      amountCents: 300,
      type: RecordType.expense,
      categoryId: 'transport',
      date: DateTime.now(),
    );
    await provider.clearAll();

    expect(provider.records, isEmpty);
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('rejects a zero amount', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    expect(
      () => provider.addRecord(
        amountCents: 0,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
      ),
      throwsArgumentError,
    );
  });

  test('switching ledgers scopes totals and persists the selection', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.addRecord(
      amountCents: 1000,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime.now(),
    );
    await provider.selectLedger('travel');
    await provider.addRecord(
      amountCents: 2500,
      type: RecordType.expense,
      categoryId: 'transport',
      date: DateTime.now(),
    );

    expect(provider.currentMonthExpenseCents, 2500);
    expect(provider.currentMonthCountForLedger('daily'), 1);
    expect(provider.totalCountForLedger('travel'), 1);

    final restored = LedgerProvider(box, meta);
    addTearDown(restored.dispose);
    expect(restored.selectedLedger.id, 'travel');
  });

  test('reminder and backup settings persist in the meta box', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.setReminderEnabled(false);
    await provider.backupNow();

    expect(provider.reminderEnabled, isFalse);
    expect(provider.lastBackupAt, isNotNull);
    expect(meta.get('reminder_enabled'), isFalse);
    expect(meta.get('backup_json'), isA<String>());
  });
}
