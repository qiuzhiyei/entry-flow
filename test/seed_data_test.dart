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
    expect(records, hasLength(45));
    expect(meta.get('demo_seeded'), isTrue);

    await records.clear();
    await SeedData.seedIfNeeded(records, meta);
    expect(records, isEmpty);
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
