export 'tones_service_stub.dart'
  if (dart.library.html) 'tones_service_web.dart'
  if (dart.library.io) 'tones_service_mobile.dart';

typedef MicLevelCallback = void Function(double level);

class TonesService {
  Future<void> init() async {}
  Future<void> playStartDing() async {}
  Future<void> playStopDing() async {}

  // Web-only helpers (no-ops on mobile)
  static Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {}
  static Future<void> stopMicLevelStream() async {}
}
