import 'package:flutter/material.dart';
import 'half_donut_gauge.dart';
import 'voice_wave.dart';

class GaugeArea extends StatelessWidget {
  final bool isListening;
  final double micLevel;          // 0..1
  final double percent;           // 0..100
  final bool showGauge;           // show gauge when not listening and we have a score
  final double size;              // diameter used only for donut
  final double thickness;

  const GaugeArea({
    super.key,
    required this.isListening,
    required this.micLevel,
    required this.percent,
    required this.showGauge,
    this.size = 150,
    this.thickness = 40,
  });

  @override
  Widget build(BuildContext context) {
    final halfHeight = size / 2;

    if (isListening) {
      // FIX: give the wave full width so it’s visible and lively.
      return SizedBox(
        height: halfHeight,
        width: double.infinity,
        child: VoiceWave(level: micLevel),
      );
    }

    // Not listening → show the fixed-size half-donut (no stretching).
    return SizedBox(
      height: halfHeight,
      child: Center(
        child: showGauge
            ? HalfDonutGauge(percent: percent, size: size, thickness: thickness)
            : const SizedBox.shrink(),
      ),
    );
  }
}
