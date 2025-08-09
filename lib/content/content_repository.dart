import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class ContentRepository {
  final Map<String, SoundContent> sounds;
  ContentRepository(this.sounds);

  static Future<ContentRepository> loadFromAssets({String path = 'assets/content.json'}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      final soundsJson = (jsonMap['sounds'] ?? {}) as Map<String, dynamic>;
      final parsed = <String, SoundContent>{};
      soundsJson.forEach((k, v) {
        parsed[k] = SoundContent.fromJson(Map<String, dynamic>.from(v));
      });
      if (parsed.isEmpty) throw Exception('No sounds parsed');
      return ContentRepository(parsed);
    } catch (_) {
      // Fallback minimal defaults if JSON missing/broken
      return ContentRepository({
        'R': SoundContent(
          words: WordBank(initial: ['rabbit'], medial: ['carrot'], finalWords: ['car']),
          introSentences: ['The red rabbit ran rapidly.'],
          shortSentences: ['The \$WORD is ready.'],
        ),
      });
    }
  }

  bool hasSound(String key) => sounds.containsKey(key);

  String randomSoundKey() {
    final keys = sounds.keys.toList();
    keys.shuffle(Random());
    return keys.first;
  }

  String randomIntroSentence(String sound) {
    final s = sounds[sound];
    return _pick(s?.introSentences ?? const ['Say this sentence.']);
  }

  String randomWord(String sound) {
    final s = sounds[sound];
    if (s == null) return 'practice';
    final all = <String>[];
    all.addAll(s.words.initial);
    all.addAll(s.words.medial);
    all.addAll(s.words.finalWords);
    return _pick(all.isEmpty ? const ['practice'] : all);
  }

  String shortSentenceWithWord(String sound, String word) {
    final s = sounds[sound];
    final tpl = _pick(s?.shortSentences ?? const ['Say \$WORD clearly.']);
    return tpl.replaceAll('\$WORD', word);
  }

  T _pick<T>(List<T> list) {
    if (list.isEmpty) throw Exception('Empty list');
    final r = Random();
    return list[r.nextInt(list.length)];
    }
}

class SoundContent {
  final WordBank words;
  final List<String> introSentences;
  final List<String> shortSentences;
  final List<String> tags;

  SoundContent({
    required this.words,
    required this.introSentences,
    required this.shortSentences,
    this.tags = const [],
  });

  factory SoundContent.fromJson(Map<String, dynamic> json) {
    final wordsJson = Map<String, dynamic>.from(json['words'] ?? {});
    return SoundContent(
      words: WordBank.fromJson(wordsJson),
      introSentences: List<String>.from(json['intro_sentences'] ?? const []),
      shortSentences: List<String>.from(json['short_sentences'] ?? const []),
      tags: List<String>.from(json['tags'] ?? const []),
    );
  }
}

class WordBank {
  final List<String> initial;
  final List<String> medial;
  final List<String> finalWords;

  WordBank({required this.initial, required this.medial, required this.finalWords});

  factory WordBank.fromJson(Map<String, dynamic> json) {
    return WordBank(
      initial: List<String>.from((json['initial'] ?? const []) as List),
      medial: List<String>.from((json['medial'] ?? const []) as List),
      finalWords: List<String>.from((json['final'] ?? const []) as List),
    );
  }
}
