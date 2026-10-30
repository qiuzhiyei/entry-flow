import 'dart:io';

import 'package:entry_flow/app.dart';
import 'package:entry_flow/models/record.dart';
import 'package:entry_flow/providers/ledger_provider.dart';
import 'package:entry_flow/screens/stats_screen.dart';
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

  testWidgets('home shows a flat month-over-month badge', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 15);
    await tester.runAsync(() async {
      await provider.addRecord(
        amountCents: 1000,
        type: RecordType.expense,
        categoryId: 'food',
        date: previous,
      );
      await provider.addRecord(
        amountCents: 1000,
        type: RecordType.expense,
        categoryId: 'food',
        date: now,
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const LedgerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('与上月持平'), findsOneWidget);
  });

  testWidgets('year stats averages only months with expenses', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LedgerProvider(box, meta);
    addTearDown(provider.dispose);

    final year = DateTime.now().year;
    await tester.runAsync(() async {
      await provider.addRecord(
        amountCents: 100000,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime(year, 1, 10),
      );
      await provider.addRecord(
        amountCents: 500000,
        type: RecordType.income,
        categoryId: 'salary',
        date: DateTime(year, 2, 10),
      );
      await provider.addRecord(
        amountCents: 300000,
        type: RecordType.expense,
        categoryId: 'food',
        date: DateTime(year, 3, 10),
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<LedgerProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: StatsScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('按年'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('月均支出'), findsOneWidget);
    expect(find.text('¥2,000'), findsOneWidget);
  });

  testWidgets('clear data needs two confirmations and a 3 second wait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await box.put(
        'clear-record',
        Record(
          id: 'clear-record',
          amountCents: 100,
          type: RecordType.expense,
          categoryId: 'food',
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
    });

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

    await tester.tap(find.text('我的').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('清理数据'));
    await tester.tap(find.text('清理数据'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('清理全部数据？'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('再次确认'), findsOneWidget);

    FilledButton finalButton() {
      return tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '请等待 3 秒'),
      );
    }

    expect(finalButton().onPressed, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('请等待 2 秒'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('请等待 1 秒'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('确认清理'), findsOneWidget);
    final ready = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '确认清理'),
    );
    expect(ready.onPressed, isNotNull);

    await tester.tap(find.text('确认清理'));
    await tester.pump();
    expect(provider.cleared, isTrue);
    expect(find.text('已清理全部账目'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}

class _RecordingLedgerProvider extends LedgerProvider {
  _RecordingLedgerProvider(super.box, super.meta);

  int? savedAmountCents;
  String? savedNote;
  bool cleared = false;

  @override
  Future<void> clearAll() async {
    cleared = true;
  }

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
