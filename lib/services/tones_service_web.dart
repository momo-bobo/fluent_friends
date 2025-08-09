import 'package:js/js.dart';

typedef MicLevelCallback = void Function(double level);

@JS('playBeep')
external void _playBeep(num freq, num durationMs);

@JS('startMicLevel')
external void _startMicLevel(void Function(num level) onLevel);

@JS('stopMicLevel')
external void _stopMicLevel();

class TonesService {
  Future<void> init() async {}

  Future<void> playStartDing() async {
    // Higher pitch, shorter
    _playBeep(880, 160);
  }

  Future<void> playStopDing() async {
    // Lower pitch, slightly longer
    _playBeep(660, 180);
  }

  Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {
    _startMicLevel(allowInterop((num level) => onLevel(level.toDouble())));
  }

  Future<void> stopMicLevelStream() async {
    _stopMicLevel();
  }
}
