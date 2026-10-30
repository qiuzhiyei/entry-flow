import 'dart:io';

import 'package:entry_flow/models/record.dart';
import 'package:entry_flow/services/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Record> records;
  late Box<dynamic> meta;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_seed_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    records = await Hive.openBox<Record>('seed_records');
    meta = await Hive.openBox<dynamic>('seed_meta');
  });

  setUp(() async {
    await records.clear();
    await meta.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('demo data is seeded once and never returns after clearing', () async {
    await SeedData.seedIfNeeded(records, meta);
    expect(records, hasLength(84));
    expect(
      records.values.where((record) => record.ledgerId == 'daily').length,
      84,
    );
    expect(
      records.values.where((record) => record.ledgerId == 'travel'),
      isEmpty,
    );
    expect(meta.get('demo_seeded'), isTrue);

    await records.clear();
    await SeedData.seedIfNeeded(records, meta);
    expect(records, isEmpty);
  });

  test('demo data is stored under the record id', () async {
    await SeedData.seedIfNeeded(records, meta);

    expect(
      records.keys.every((key) => key is String && key == records.get(key)?.id),
      isTrue,
    );
  });

  test('upgrading legacy demo data with integer keys does not crash', () async {
    await records.put(
      0,
      Record(
        id: 'demo-legacy',
        amountCents: 100,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await meta.put('demo_seeded', true);
    await meta.put('demo_version', 1);

    await SeedData.seedIfNeeded(records, meta);

    expect(meta.get('demo_version'), 2);
    expect(records.length, greaterThan(1));
    expect(
      records.values.where((record) => record.id == 'demo-legacy'),
      hasLength(1),
    );
  });

  test('legacy travel records are removed or merged into daily', () async {
    await records.put(
      0,
      Record(
        id: 'demo-travel-0',
        amountCents: 100,
        type: RecordType.expense,
        categoryId: 'transport',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        ledgerId: 'travel',
      ),
    );
    await records.put(
      'user-travel',
      Record(
        id: 'user-travel',
        amountCents: 200,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        ledgerId: 'travel',
      ),
    );

    await SeedData.seedIfNeeded(records, meta);

    expect(
      records.values.where((record) => record.id == 'demo-travel-0'),
      isEmpty,
    );
    final migrated = records.values.firstWhere(
      (record) => record.id == 'user-travel',
    );
    expect(migrated.ledgerId, 'daily');
    expect(meta.get('single_ledger_migrated'), isTrue);
  });

  test('an existing ledger is never polluted with demo data', () async {
    await records.put(
      'manual-1',
      Record(
        id: 'manual-1',
        amountCents: 100,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    await SeedData.seedIfNeeded(records, meta);

    expect(records, hasLength(1));
    expect(records.get('manual-1')?.note, '');
    expect(meta.get('demo_seeded'), isTrue);
  });
}
