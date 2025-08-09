import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  String? _preferredVoiceName;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true); // IMPORTANT: allow awaiting

    final voices = await _tts.getVoices;
    final list = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];
    if (_preferredVoiceName != null) {
      final match = _findByName(list, _preferredVoiceName!);
      if (match != null) { await _tts.setVoice(match); }
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> speakAndWait(String text) async {
    await _tts.stop();
    await _tts.speak(text);
    // awaitSpeakCompletion(true) set in init ensures speak() completes Future when done
    // Some platforms still need a small buffer:
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<List<String>> listVoices() async {
    final voices = await _tts.getVoices;
    final list = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];
    return list
        .map((v) => Map<String, dynamic>.from(v as Map))
        .map((m) => (m['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<bool> setPreferredVoice(String name) async {
    _preferredVoiceName = name;
    final voices = await _tts.getVoices;
    final list = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];
    final match = _findByName(list, name);
    if (match != null) {
      await _tts.setVoice(match);
      return true;
    }
    return false;
  }

  Map<String, dynamic>? _findByName(List<dynamic> raw, String name) {
    for (final v in raw) {
      final m = Map<String, dynamic>.from(v as Map);
      if ((m['name'] ?? '').toString() == name) return m;
    }
    return null;
  }
}
