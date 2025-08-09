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

    // Apply preferred voice if any, else pick best female (or best overall)
    if (_preferredVoiceName != null) {
      final match = _findByName(list, _preferredVoiceName!);
      if (match != null) {
        await _tts.setVoice(match);
      }
    } else if (list.isNotEmpty) {
      final best = _pickBestVoice(list, preferFemale: true);
      if (best != null) {
        await _tts.setVoice(best);
        _preferredVoiceName = best['name']?.toString();
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

  // Return TOP 5 FEMALE names (if gender available), else heuristic by name; fallback to top 5 overall.
  Future<List<String>> listVoices() async {
    final voices = await _tts.getVoices;
    final raw = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];

    // Score and sort
    final scored = raw
        .map((v) => Map<String, dynamic>.from(v as Map))
        .map((m) => {'m': m, 's': _score(m)})
        .toList()
      ..sort((a, b) => (b['s'] as int).compareTo(a['s'] as int));

    // Filter female first (gender='female' or name heuristic)
    List<Map<String, dynamic>> female = scored
        .where((e) => _isFemale(e['m']))
        .map((e) => e['m'] as Map<String, dynamic>)
        .toList();

    final top = (female.isNotEmpty ? female : scored.map((e) => e['m'] as Map<String, dynamic>).toList())
        .take(5)
        .map((m) => (m['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();

    return top;
  }

  Future<bool> setPreferredVoice(String name) async {
    _preferredVoiceName = name;
    final voices = await _tts.getVoices;
    final raw = (voices is List) ? voices.cast<dynamic>() : <dynamic>[];
    final match = _findByName(raw, name);
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

  // Score similar to web
  int _score(Map<String, dynamic> m) {
    int score = 0;
    final name = (m['name'] ?? '').toString().toLowerCase();
    final locale = (m['locale'] ?? '').toString().toLowerCase();

    if (locale == 'en-us') score += 6;
    else if (locale.startsWith('en-')) score += 4;
    else if (locale.startsWith('en')) score += 3;

    if (name.contains('google')) score += 4;
    if (name.contains('microsoft')) score += 4;
    if (name.contains('apple') || name.contains('siri')) score += 3;
    if (name.contains('wavenet') || name.contains('neural') || name.contains('natural')) score += 3;

    if (name.contains('default') || name.contains('basic') || name.contains('compact')) score -= 3;

    if (_isFemale(m)) score += 3;

    return score;
  }

  bool _isFemale(Map<String, dynamic> m) {
    final gender = (m['gender'] ?? '').toString().toLowerCase();
    if (gender == 'female') return true;
    final name = (m['name'] ?? '').toString().toLowerCase();
    const femaleHints = [
      'female', 'woman', 'girl',
      'aria', 'jessa', 'jenny', 'emma', 'lisa', 'sara', 'sarah', 'salli', 'joanna', 'ivy', 'zoe', 'zoey'
    ];
    return femaleHints.any((h) => name.contains(h));
  }

  Map<String, dynamic>? _pickBestVoice(List<dynamic> raw, {bool preferFemale = false}) {
    Map<String, dynamic>? best;
    int bestScore = -999;

    for (final v in raw) {
      final m = Map<String, dynamic>.from(v as Map);
      int s = _score(m);
      if (preferFemale && !_isFemale(m)) {
        // small nudge to favor female when tie
        s -= 1;
      }
      if (s > bestScore) {
        best = m;
        bestScore = s;
      }
    }
    return best;
  }
}
