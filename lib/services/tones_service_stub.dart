import 'tones_service.dart';

class TonesService {
  Future<void> init() async {}
  Future<void> playStartDing() async {}
  Future<void> playStopDing() async {}

  static Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {}
  static Future<void> stopMicLevelStream() async {}
}
