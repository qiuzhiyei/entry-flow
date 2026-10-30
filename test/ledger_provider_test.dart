import 'dart:convert';
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

  test('merge import updates a legacy integer-keyed record in place', () async {
    final legacy = Record(
      id: 'legacy-1',
      amountCents: 1000,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await box.put(7, legacy);

    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final json = jsonEncode(<Map<String, dynamic>>[
      legacy.copyWith(amountCents: 2000).toJson(),
    ]);
    final summary = await provider.importBackup(json, replace: false);

    expect(summary.imported, 1);
    expect(box.length, 1);
    expect(provider.allRecords.single.amountCents, 2000);
  });

  test(
    'deleteRecord removes a legacy integer-keyed record by its id',
    () async {
      await box.put(
        3,
        Record(
          id: 'legacy-delete',
          amountCents: 100,
          type: RecordType.expense,
          categoryId: 'food',
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      final provider = LedgerProvider(box, meta);
      addTearDown(provider.dispose);

      await provider.deleteRecord('legacy-delete');

      expect(box, isEmpty);
      expect(provider.allRecords, isEmpty);
    },
  );

  test('backup timestamp and snapshot persist in the meta box', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.backupNow();

    expect(provider.lastBackupAt, isNotNull);
    expect(meta.get('backup_json'), isA<String>());
  });

  test('exported JSON restores records and settings with replace', () async {
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

    final json = provider.buildBackupJson();
    expect(json, contains('"schemaVersion": 1'));
    expect(json, contains('"selectedLedger": "travel"'));

    await provider.clearAll();
    expect(provider.allRecords, isEmpty);

    final summary = await provider.importBackup(json, replace: true);

    expect(summary.imported, 2);
    expect(summary.skipped, 0);
    expect(summary.replaced, isTrue);
    expect(provider.allRecords, hasLength(2));
    expect(provider.selectedLedger.id, 'travel');
    expect(provider.currentMonthExpenseCents, 2500);
  });

  test('merge import keeps existing records and dedupes by id', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await provider.addRecord(
      amountCents: 1000,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime.now(),
    );
    final json = provider.buildBackupJson();
    await provider.addRecord(
      amountCents: 2500,
      type: RecordType.expense,
      categoryId: 'transport',
      date: DateTime.now(),
    );

    final summary = await provider.importBackup(json, replace: false);

    expect(summary.imported, 1);
    expect(summary.replaced, isFalse);
    expect(provider.allRecords, hasLength(2));
    expect(provider.currentMonthExpenseCents, 3500);
  });

  test('old raw-list backups are still accepted', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final raw = jsonEncode(<Map<String, dynamic>>[
      Record(
        id: 'raw-1',
        amountCents: 700,
        type: RecordType.expense,
        categoryId: 'study',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ).toJson(),
    ]);
    final summary = await provider.importBackup(raw, replace: true);

    expect(summary.imported, 1);
    expect(provider.records.single.categoryId, 'study');
  });

  test('records with invalid dates are skipped on import', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final invalid = Record(
      id: 'bad-date',
      amountCents: 100,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    ).toJson();
    invalid['date'] = 'not-a-date';
    final json = jsonEncode(<Map<String, dynamic>>[invalid]);

    final preview = provider.parseBackup(json);
    expect(preview.records, isEmpty);
    expect(preview.skipped, 1);
    await expectLater(
      provider.importBackup(json, replace: true),
      throwsA(isA<FormatException>()),
    );
  });

  test('invalid backup files are rejected', () async {
    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    expect(() => provider.parseBackup('{not-json'), throwsFormatException);
    await expectLater(
      provider.importBackup('{"records":[]}', replace: true),
      throwsA(isA<FormatException>()),
    );
  });
}
