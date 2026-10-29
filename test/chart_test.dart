import 'package:entry_flow/providers/ledger_provider.dart';
import 'package:entry_flow/widgets/finance_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a bar shows a tooltip without errors', (tester) async {
    final data = <MonthlyTotal>[
      for (var i = 1; i <= 6; i++)
        MonthlyTotal(
          month: DateTime(2026, i),
          expenseCents: 100000 + i * 10000,
          incomeCents: 300000 + i * 20000,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 314, child: MonthlyBarChart(data: data)),
          ),
        ),
      ),
    );
    await tester.pump();

    final chart = find.byType(MonthlyBarChart);
    expect(chart, findsOneWidget);
    final topLeft = tester.getTopLeft(chart);
    await tester.tapAt(topLeft + const Offset(150, 90));
    await tester.pump();

    final exception = tester.takeException();
    if (exception != null) {
      debugPrint('CHART EXCEPTION: $exception');
    }
    expect(exception, isNull);
  });
}
