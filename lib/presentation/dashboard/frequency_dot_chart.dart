import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../theme/ficon_theme.dart';
import 'dashboard_section_header.dart';

class FrequencyDotChart extends StatelessWidget {
  const FrequencyDotChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String title;
  final String subtitle;
  final List<FrequencyPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      0,
      (maximum, point) => math.max(maximum, point.count),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              icon: Icons.show_chart_outlined,
              color: FiconColors.logoBlue,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
            Semantics(
              label: '$title. ${points.length} días representados.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.max(
                    constraints.maxWidth,
                    38 + points.length * 23,
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CustomPaint(
                      size: Size(width.toDouble(), 190),
                      painter: _DotChartPainter(
                        points: points,
                        maxValue: math.max(1, maxValue),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotChartPainter extends CustomPainter {
  const _DotChartPainter({required this.points, required this.maxValue});

  final List<FrequencyPoint> points;
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const top = 10.0;
    const bottom = 28.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left - 10;
    final gridPaint = Paint()
      ..color = FiconColors.cardBorderSoft
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = FiconColors.slate
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = FiconColors.logoBlue;
    final linePaint = Paint()
      ..color = FiconColors.logoBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var step = 0; step <= 4; step++) {
      final y = top + chartHeight * step / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - 10, y), gridPaint);
      final value = (maxValue * (4 - step) / 4).round();
      _text(canvas, '$value', Offset(0, y - 7), FiconColors.slate);
    }
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );

    if (points.isEmpty) return;
    final spacing = points.length == 1
        ? chartWidth
        : chartWidth / (points.length - 1);
    final line = Path();
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = left + spacing * index;
      final y = top + chartHeight * (1 - point.count / maxValue);
      if (index == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    canvas.drawPath(line, linePaint);
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = left + spacing * index;
      final y = top + chartHeight * (1 - point.count / maxValue);
      canvas.drawCircle(Offset(x, y), point.count == 0 ? 3 : 4.5, dotPaint);
      if (index == 0 || index == points.length - 1 || (index + 1) % 5 == 0) {
        _text(
          canvas,
          point.label,
          Offset(x - 7, top + chartHeight + 8),
          FiconColors.deepAlt,
        );
      }
    }
  }

  void _text(Canvas canvas, String value, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DotChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}
