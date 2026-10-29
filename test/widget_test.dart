import 'dart:io';

import 'package:entry_flow/app.dart';
import 'package:entry_flow/models/record.dart';
import 'package:entry_flow/providers/ledger_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;
  late Box<Record> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_widget_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    box = await Hive.openBox<Record>('widget_records');
  });

  setUp(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('home reflects an empty box and refreshes after a write', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LedgerProvider(box);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const LedgerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('最近交易'), findsOneWidget);
    expect(find.text('这个月还没有记录'), findsOneWidget);
    expect(find.text('暂无上月数据'), findsOneWidget);

    // Hive writes hit the real file system; run them outside the widget
    // test's fake async zone.
    await tester.runAsync(
      () => provider.addRecord(
        amountCents: 1250,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime.now(),
        note: '午饭',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('这个月还没有记录'), findsNothing);
    expect(find.text('午饭'), findsOneWidget);
    expect(find.text('−¥12.50'), findsOneWidget);

    await tester.runAsync(provider.clearAll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('这个月还没有记录'), findsOneWidget);
  });
}
