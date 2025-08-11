import 'package:flutter/material.dart';
import 'half_donut_gauge.dart';
import 'voice_wave.dart';

class GaugeArea extends StatelessWidget {
  final bool isListening;
  final double micLevel;          // 0..1
  final double percent;           // 0..100
  final bool showGauge;           // show gauge when not listening and we have a score
  final double size;              // diameter of the circle the half-donut is based on
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
    // Fix: lock both width and height so it cannot stretch horizontally.
    final halfHeight = size / 2;
    return SizedBox(
      width: size,
      height: halfHeight,
      child: Center(
        child: isListening
            ? VoiceWave(level: micLevel)
            : (showGauge
                ? HalfDonutGauge(percent: percent, size: size, thickness: thickness)
                : const SizedBox.shrink()),
      ),
    );
  }
}
