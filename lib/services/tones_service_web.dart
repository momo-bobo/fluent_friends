// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:js/js.dart';
import 'tones_service.dart';

@JS('playBeep')
external void _playBeep(num freq, num durationMs);

@JS('startMicLevel')
external void _startMicLevel(void Function(num level) onLevel);

@JS('stopMicLevel')
external void _stopMicLevel();

class TonesService {
  Future<void> init() async {}

  Future<void> playStartDing() async {
    _playBeep(880, 160); // higher ding
  }

  Future<void> playStopDing() async {
    _playBeep(660, 180); // lower ding
  }

  static Future<void> startMicLevelStream({required MicLevelCallback onLevel}) async {
    _startMicLevel(allowInterop((num level) {
      onLevel(level.toDouble());
    }));
  }

  static Future<void> stopMicLevelStream() async {
    _stopMicLevel();
  }
}
