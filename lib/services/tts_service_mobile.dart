import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  String? _preferredVoiceName;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    final voices = await _tts.getVoices;
    final list = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];

    // pick a best voice if none chosen
    if (_preferredVoiceName == null && list.isNotEmpty) {
      final best = _pickBestVoice(list);
      if (best != null) {
        await _tts.setVoice(best);
        _preferredVoiceName = best['name']?.toString();
      }
    } else if (_preferredVoiceName != null) {
      // try to apply preferred voice by name
      final match = list
          .map((v) => Map<String, dynamic>.from(v as Map))
          .firstWhere(
              (m) => (m['name'] ?? '').toString() == _preferredVoiceName,
              orElse: () => {});
      if (match.isNotEmpty) {
        await _tts.setVoice(match);
      }
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
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
    final match = list
        .map((v) => Map<String, dynamic>.from(v as Map))
        .firstWhere((m) => (m['name'] ?? '').toString() == name,
            orElse: () => {});
    if (match.isNotEmpty) {
      await _tts.setVoice(match);
      return true;
    }
    return false;
  }

  Map<String, dynamic>? _pickBestVoice(List<dynamic> raw) {
    Map<String, dynamic>? best;
    int bestScore = -999;

    for (final v in raw) {
      final map = Map<String, dynamic>.from(v as Map);
      final name = (map['name'] ?? '').toString();
      final locale = (map['locale'] ?? '').toString().toLowerCase();

      int score = 0;
      if (locale == 'en-us') score += 6;
      else if (locale.startsWith('en-')) score += 4;
      else if (locale.startsWith('en')) score += 3;

      final lname = name.toLowerCase();
      if (lname.contains('google')) score += 4;
      if (lname.contains('microsoft')) score += 4;
      if (lname.contains('apple') || lname.contains('siri')) score += 3;
      if (lname.contains('wavenet') || lname.contains('neural') || lname.contains('natural')) score += 3;

      if (lname.contains('default') || lname.contains('basic') || lname.contains('compact')) score -= 3;

      if (score > bestScore) {
        best = map;
        bestScore = score;
      }
    }
    return best;
  }
}
