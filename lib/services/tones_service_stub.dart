typedef MicLevelCallback = void Function(double level);

class TonesService {
  Future<void> init() async {}

  Future<void> playStartDing() async {}
  Future<void> playStopDing() async {}

  Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {}
  Future<void> stopMicLevelStream() async {}
}
