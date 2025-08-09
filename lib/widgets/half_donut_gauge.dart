import 'package:flutter/material.dart';
import 'dart:math' as math;

class HalfDonutGauge extends StatelessWidget {
  final double percent; // 0–100
  final double size;
  final double thickness;

  const HalfDonutGauge({
    super.key,
    required this.percent,
    required this.size,
    this.thickness = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size / 2),
      painter: _HalfDonutPainter(
        percent: percent,
        thickness: thickness,
      ),
    );
  }
}

class _HalfDonutPainter extends CustomPainter {
  final double percent;
  final double thickness;

  _HalfDonutPainter({required this.percent, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // background arc
    canvas.drawArc(rect, math.pi, math.pi, false, basePaint);

    // progress arc
    final sweepAngle = math.pi * (percent / 100.0);
    canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
