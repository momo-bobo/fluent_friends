import 'package:flutter/services.dart';
import 'tones_service.dart';

class TonesService {
  Future<void> init() async {}

  // Placeholder: system click (twice on stop for a different feel).
  Future<void> playStartDing() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playStopDing() async {
    await SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 120));
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {}
  static Future<void> stopMicLevelStream() async {}
}
