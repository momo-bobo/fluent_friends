import 'dart:math' as math;
import 'package:flutter/material.dart';

class HalfDonutGauge extends StatelessWidget {
  final double percent; // 0..100
  final double size;    // overall size in px
  final double thickness;

  const HalfDonutGauge({
    super.key,
    required this.percent,
    this.size = 260,
    this.thickness = 24,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size / 2 + thickness / 2,
      child: CustomPaint(
        painter: _HalfDonutPainter(
          percent: clamped.toDouble(),
          thickness: thickness,
          bgColor: Colors.black12,
          fillColor: Colors.green,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: thickness / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${clamped.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfDonutPainter extends CustomPainter {
  final double percent; // 0..100
  final double thickness;
  final Color bgColor;
  final Color fillColor;

  _HalfDonutPainter({
    required this.percent,
    required this.thickness,
    required this.bgColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final radius = width / 2;
    final rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - thickness / 2);

    final start = math.pi; // left (180°)
    final sweepFull = math.pi; // 180° total for half donut
    final sweepValue = sweepFull * (percent / 100.0);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = bgColor;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = fillColor;

    // Background arc (full half ring)
    canvas.drawArc(rect, start, sweepFull, false, bgPaint);

    // Foreground arc (progress)
    if (percent > 0) {
      canvas.drawArc(rect, start, sweepValue, false, fgPaint);

      // Indicator dot at the end of the fill arc
      final endAngle = start + sweepValue;
      final cx = rect.center.dx + (rect.width / 2) * math.cos(endAngle);
      final cy = rect.center.dy + (rect.height / 2) * math.sin(endAngle);
      final dotPaint = Paint()..color = fillColor;
      canvas.drawCircle(Offset(cx, cy), thickness * 0.3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfDonutPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.thickness != thickness ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.fillColor != fillColor;
  }
}
