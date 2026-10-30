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
  late Box<dynamic> meta;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_flow_widget_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    box = await Hive.openBox<Record>('widget_records');
    meta = await Hive.openBox<dynamic>('widget_meta');
  });

  setUp(() async {
    await box.clear();
    await meta.clear();
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

    final provider = LedgerProvider(box, meta);
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

  testWidgets('data backup sheet opens from the profile tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const LedgerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('我的').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('通用设置'), findsOneWidget);

    await tester.tap(find.text('数据备份'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('导出备份'), findsOneWidget);
    expect(find.text('导入备份'), findsOneWidget);
  });

  testWidgets('add screen can save while the note field is focused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = _RecordingLedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const LedgerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('记一笔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('支出'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('0').last);
    await tester.pump();
    await tester.tap(find.text('0').last);
    await tester.pump();
    expect(find.text('300'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '午饭');
    await tester.pump();

    expect(find.text('完成'), findsNothing);
    expect(find.text('保存'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(provider.savedAmountCents, 30000);
    expect(provider.savedNote, '午饭');
    expect(find.text('支出'), findsNothing);
    expect(find.text('最近交易'), findsOneWidget);
    expect(find.text('已记录：餐饮 300.00 元'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // The success toast schedules a 2s timer; advance fake time so it can
    // fire before the test tears down.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('tapping the amount restores the keypad after note focus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const LedgerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('记一笔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('0').last);
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '午饭');
    await tester.pump();
    expect(find.text('完成'), findsNothing);

    await tester.tap(find.text('¥'));
    await tester.pump();

    expect(find.text('完成'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isFalse);
  });
}

class _RecordingLedgerProvider extends LedgerProvider {
  _RecordingLedgerProvider(super.box, super.meta);

  int? savedAmountCents;
  String? savedNote;

  @override
  Future<void> addRecord({
    required int amountCents,
    required RecordType type,
    required String categoryId,
    required DateTime date,
    String note = '',
  }) async {
    savedAmountCents = amountCents;
    savedNote = note;
  }
}
