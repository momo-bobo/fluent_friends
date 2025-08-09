import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A gentle, pastel-green bar visualizer that reacts to mic [level] (0..1).
/// Includes light smoothing so it doesn't flicker.
class VoiceWave extends StatefulWidget {
  final double level; // 0..1

  const VoiceWave({super.key, required this.level});

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  double _smoothed = 0.0;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Exponential smoothing toward the incoming level
    const alpha = 0.3;
    _smoothed = _smoothed + alpha * (widget.level - _smoothed);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        return CustomPaint(
          painter: _BarsPainter(
            anim: _ac.value,
            level: _smoothed,
          ),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final double anim;  // 0..1 loop
  final double level; // 0..1 (smoothed)

  _BarsPainter({required this.anim, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3CB371).withOpacity(0.6) // pastel green
      ..style = PaintingStyle.fill;

    // Layout: a centered row of bars
    const int bars = 14;
    final gap = size.width * 0.01;
    final barWidth = (size.width - gap * (bars - 1)) / bars;
    final midY = size.height * 0.70;

    // Base amplitude mapping; keep it gentle
    final baseAmp = size.height * 0.55;
    final amp = baseAmp * (0.15 + 0.85 * level.clamp(0.0, 1.0));

    for (int i = 0; i < bars; i++) {
      final x = i * (barWidth + gap);
      final centerOffset = (i - (bars - 1) / 2.0).abs() / ((bars - 1) / 2.0);
      final centerBias = 1.0 - centerOffset * 0.6;

      final phase = anim * 2 * math.pi + i * 0.45;
      final ripple = 0.85 + 0.15 * math.sin(phase);

      final h = (amp * centerBias * ripple).clamp(6.0, size.height);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, midY - h / 2, barWidth, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.anim != anim || old.level != level;
}
