import 'dart:io';

import 'package:entry_flow/models/record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_persist_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('a record survives closing and reopening the box', () async {
    var box = await Hive.openBox<Record>('roundtrip');
    final record = Record(
      id: 'record-1',
      amountCents: 1250,
      type: RecordType.expense,
      categoryId: 'food',
      date: DateTime(2026, 10, 29, 12, 26),
      note: '午饭',
      createdAt: DateTime(2026, 10, 29, 12, 26, 30),
    );
    await box.put(record.id, record);
    await box.close();

    box = await Hive.openBox<Record>('roundtrip');
    final restored = box.get('record-1');

    expect(restored, isNotNull);
    expect(restored!.id, 'record-1');
    expect(restored.amountCents, 1250);
    expect(restored.type, RecordType.expense);
    expect(restored.categoryId, 'food');
    expect(restored.note, '午饭');
    expect(restored.date, DateTime(2026, 10, 29, 12, 26));
    expect(restored.createdAt, DateTime(2026, 10, 29, 12, 26, 30));
  });
}
