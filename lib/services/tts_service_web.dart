import 'dart:js' as js;
import '../web_tts_bridge.dart';

class TtsService {
  Future<void> init() async {
    // no-op for web
  }

  Future<void> speak(String text) async {
    js.context.callMethod('speakText', [text]);
  }

  Future<void> stop() async {
    js.context.callMethod('stopSpeaking', []);
  }
}
