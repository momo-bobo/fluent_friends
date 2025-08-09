import 'dart:js_util' as js_util;
import '../web_tts_bridge.dart';

class TtsService {
  Future<void> init() async {}

  Future<void> speak(String text) async {
    speakText(text);
  }

  Future<void> stop() async {
    stopSpeaking();
  }

  Future<void> speakAndWait(String text) async {
    final promise = speakTextAndWait(text);
    await js_util.promiseToFuture(promise);
  }

  Future<List<String>> listVoices() async {
    try {
      final arr = getVoiceNames();
      return arr.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<bool> setPreferredVoice(String name) async {
    try {
      return setPreferredVoiceByName(name);
    } catch (_) {
      return false;
    }
  }
}
