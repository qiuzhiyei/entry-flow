import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

@immutable
class DonutSlice {
  const DonutSlice({
    required this.name,
    required this.color,
    required this.cents,
  });

  final String name;
  final Color color;
  final int cents;
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, required this.totalCents});

  static const double diameter = 196;

  final List<DonutSlice> slices;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size.square(diameter),
            painter: _DonutPainter(slices: slices, totalCents: totalCents),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '总支出',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Money.formatShortCents(totalCents),
                style: const TextStyle(
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.525,
                  color: AppColors.ink,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.totalCents});

  final List<DonutSlice> slices;
  final int totalCents;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (62 / 160);
    final strokeWidth = size.shortestSide * (26 / 160);
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (totalCents <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFEDF1ED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    var start = -math.pi / 2;
    final gap = 3 / radius;
    for (final slice in slices) {
      if (slice.cents <= 0) continue;
      final sweep = slice.cents / totalCents * math.pi * 2;
      final paintedSweep = math.max(sweep - gap, 0.002);
      canvas.drawArc(
        rect,
        start,
        paintedSweep,
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.totalCents != totalCents ||
        oldDelegate.slices.length != slices.length ||
        oldDelegate.slices != slices;
  }
}

/// A 6- or 12-month grouped bar chart with the prototype's tooltip behavior.
class MonthlyBarChart extends StatefulWidget {
  const MonthlyBarChart({super.key, required this.data});

  final List<MonthlyTotal> data;

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  int? _selected;

  static const double _left = 32;
  static const double _right = 334;
  static const double _top = 14;
  static const double _bottom = 152;

  @override
  void didUpdateWidget(covariant MonthlyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null && _selected! >= widget.data.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 340 / 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _select(details.localPosition, size),
                child: MouseRegion(
                  onHover: (event) => _select(event.localPosition, size),
                  onExit: (_) {
                    if (_selected != null) setState(() => _selected = null);
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _BarChartPainter(data: widget.data),
                  ),
                ),
              ),
              if (_selected != null) _buildTooltip(size, _selected!),
            ],
          );
        },
      ),
    );
  }

  void _select(Offset position, Size size) {
    if (widget.data.isEmpty) return;
    final x = position.dx / size.width * 340;
    if (x < _left || x > _right) {
      if (_selected != null) setState(() => _selected = null);
      return;
    }
    final band = (_right - _left) / widget.data.length;
    final index = ((x - _left) / band).floor().clamp(0, widget.data.length - 1);
    if (_selected != index) setState(() => _selected = index);
  }

  Widget _buildTooltip(Size size, int index) {
    final item = widget.data[index];
    final maxValue = _niceMax(widget.data);
    final band = (_right - _left) / widget.data.length;
    final center = _left + band * (index + 0.5);
    final scale = (_bottom - _top) / maxValue;
    final expenseTop = _bottom - (item.expenseCents / 100) * scale;
    final incomeTop = _bottom - (item.incomeCents / 100) * scale;
    final top = math.min(expenseTop, incomeTop) - 8;
    final left = (center / 340 * size.width).clamp(
      size.width * 0.2,
      size.width * 0.8,
    );
    final topPx = (top / 200 * size.height).clamp(0.0, size.height);

    return Positioned(
      left: left,
      top: topPx,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1),
          child: Container(
            constraints: BoxConstraints(maxWidth: size.width * 0.86),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x990A1914),
                  offset: Offset(0, 8),
                  blurRadius: 18,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Text(
              '${item.month.month}月 · 支出 ${Money.formatCents(item.expenseCents)}'
              ' · 收入 ${Money.formatCents(item.incomeCents)}',
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.data});

  final List<MonthlyTotal> data;

  static const double _left = 32;
  static const double _right = 334;
  static const double _top = 14;
  static const double _bottom = 152;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 340, size.height / 200);

    final maxValue = _niceMax(data);
    final gridPaint = Paint()
      ..color = const Color(0xFFE7ECE7)
      ..strokeWidth = 1;
    final baselinePaint = Paint()
      ..color = const Color(0xFFD8E0DA)
      ..strokeWidth = 1;

    // Grid lines and y-axis labels.
    for (final fraction in <double>[0, 0.5, 1]) {
      final value = maxValue * fraction;
      final y = _bottom - (_bottom - _top) * fraction;
      canvas.drawLine(Offset(_left, y), Offset(_right, y), gridPaint);
      _paintText(
        canvas,
        _axisLabel(value),
        Offset(_left - 6, y + 3.5),
        fontSize: 9.5,
        anchorRight: true,
      );
    }

    final band = (_right - _left) / data.length;
    final barWidth = data.length > 6 ? 8.0 : 13.0;
    final gap = data.length > 6 ? 1.2 : 1.5;
    final scale = (_bottom - _top) / maxValue;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final center = _left + band * (i + 0.5);
      final expenseHeight = (item.expenseCents / 100) * scale;
      final incomeHeight = (item.incomeCents / 100) * scale;

      _drawBar(
        canvas,
        center - barWidth - gap,
        _bottom - expenseHeight,
        barWidth,
        expenseHeight,
        AppColors.mint,
      );
      _drawBar(
        canvas,
        center + gap,
        _bottom - incomeHeight,
        barWidth,
        incomeHeight,
        AppColors.amber,
      );
      _paintText(
        canvas,
        '${item.month.month}月',
        Offset(center, _bottom + 20),
        fontSize: data.length > 6 ? 8 : 9.5,
        centered: true,
      );
    }

    canvas.drawLine(
      const Offset(_left, _bottom),
      const Offset(_right, _bottom),
      baselinePaint,
    );
    canvas.restore();
  }

  void _drawBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    if (height <= 0.4) return;
    final radius = math.min(4.0, math.min(width / 2, height));
    final path = Path()
      ..moveTo(x, y + height)
      ..lineTo(x, y + radius)
      ..quadraticBezierTo(x, y, x + radius, y)
      ..lineTo(x + width - radius, y)
      ..quadraticBezierTo(x + width, y, x + width, y + radius)
      ..lineTo(x + width, y + height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    bool centered = false,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.2,
          color: AppColors.ink3,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = position.dx;
    if (centered) {
      dx -= painter.width / 2;
    } else if (anchorRight) {
      dx -= painter.width;
    }
    painter.paint(canvas, Offset(dx, position.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

double _niceMax(List<MonthlyTotal> data) {
  var value = 1.0;
  for (final item in data) {
    value = math.max(
      value,
      math.max(item.expenseCents, item.incomeCents) / 100,
    );
  }
  if (value <= 1000) return 1000;
  return (value / 2000).ceil() * 2000;
}

String _axisLabel(double value) {
  if (value == 0) return '0';
  if (value >= 10000) {
    final amount = value / 10000;
    return '${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1)}万';
  }
  final amount = value / 1000;
  return '${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1)}千';
}
