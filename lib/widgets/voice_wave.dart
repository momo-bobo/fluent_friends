import 'dart:math' as math;
import 'package:flutter/material.dart';

class VoiceWave extends StatefulWidget {
  const VoiceWave({super.key});

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gentle ambient wave; on web we also update via JS level to affect height indirectly
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        return CustomPaint(
          painter: _WavePainter(progress: _ac.value),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3CB371).withOpacity(0.5) // pastel green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height * 0.6;
    final amp = size.height * 0.35;

    const cycles = 2.0;
    for (double x = 0; x <= size.width; x += 2) {
      final t = (x / size.width) * (2 * math.pi * cycles) + progress * 2 * math.pi;
      final y = midY + math.sin(t) * amp * 0.7 + math.sin(t * 0.5) * amp * 0.3;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.progress != progress;
}
