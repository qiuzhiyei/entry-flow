import 'dart:io';

import 'package:entry_flow/models/record.dart';
import 'package:entry_flow/services/data_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Record> records;
  late Box<dynamic> meta;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_migration_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    records = await Hive.openBox<Record>('migration_records');
    meta = await Hive.openBox<dynamic>('migration_meta');
  });

  setUp(() async {
    await records.clear();
    await meta.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('a fresh install stays empty', () async {
    await DataMigration.migrate(records, meta);

    expect(records, isEmpty);
    expect(meta.get('clean_ledger_v1'), isTrue);
  });

  test('demo records are removed and real records survive', () async {
    await records.put(
      0,
      Record(
        id: 'demo-daily-0',
        amountCents: 100,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await records.put(
      'demo-travel-0',
      Record(
        id: 'demo-travel-0',
        amountCents: 200,
        type: RecordType.expense,
        categoryId: 'transport',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        ledgerId: 'travel',
      ),
    );
    await records.put(
      'manual-1',
      Record(
        id: 'manual-1',
        amountCents: 300,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    await DataMigration.migrate(records, meta);

    expect(records, hasLength(1));
    expect(records.get('manual-1')?.amountCents, 300);
    expect(records.get('manual-1')?.ledgerId, 'daily');
  });

  test('real legacy travel records move into the daily ledger', () async {
    await records.put(
      'user-travel',
      Record(
        id: 'user-travel',
        amountCents: 500,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        ledgerId: 'travel',
      ),
    );

    await DataMigration.migrate(records, meta);

    expect(records.get('user-travel')?.ledgerId, 'daily');
    expect(records, hasLength(1));
  });

  test('legacy demo flags are cleared without touching real records', () async {
    await records.put(
      'manual-2',
      Record(
        id: 'manual-2',
        amountCents: 400,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await meta.put('demo_seeded', true);
    await meta.put('demo_version', 2);

    await DataMigration.migrate(records, meta);

    expect(records.get('manual-2')?.amountCents, 400);
    expect(meta.get('demo_seeded'), isNull);
    expect(meta.get('demo_version'), isNull);
  });
}
