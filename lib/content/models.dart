import 'dart:convert';

/// Represents the type of content in the JSON files.
enum ContentType { assessmentStory, sentenceSet, wordSet }

/// Helper to map the `type` string in JSON to our ContentType enum.
ContentType _typeFromString(String s) {
  switch (s) {
    case 'assessment_story':
      return ContentType.assessmentStory;
    case 'sentence_set':
      return ContentType.sentenceSet;
    case 'word_set':
      return ContentType.wordSet;
    default:
      throw ArgumentError('Unknown content type: $s');
  }
}

/// The top-level index.json structure.
class ContentIndex {
  final int version;
  final List<String> locales;
  final List<ContentPointer> assessment;
  final List<ContentPointer> sentences;
  final List<ContentPointer> words;

  ContentIndex({
    required this.version,
    required this.locales,
    required this.assessment,
    required this.sentences,
    required this.words,
  });

  factory ContentIndex.fromJson(Map<String, dynamic> json) {
    final sets = (json['sets'] as Map<String, dynamic>? ?? {});
    List<ContentPointer> _parseList(String key) {
      final list = (sets[key] as List?) ?? const [];
      return list.map((e) => ContentPointer.fromJson(e)).toList();
    }
    return ContentIndex(
      version: (json['version'] ?? 1) as int,
      locales: (json['locales'] as List? ?? const ['en']).cast<String>(),
      assessment: _parseList('assessment'),
      sentences: _parseList('sentences'),
      words: _parseList('words'),
    );
  }

  static ContentIndex fromString(String s) =>
      ContentIndex.fromJson(jsonDecode(s));
}

/// Points to a specific content file.
class ContentPointer {
  final String id;
  final String? path;
  final String locale;
  final Map<String, dynamic>? inline; // NEW: optional inline payload

  ContentPointer({
    required this.id,
    required this.locale,
    this.path,
    this.inline,
  });

  factory ContentPointer.fromJson(Map<String, dynamic> json) => ContentPointer(
        id: json['id'] as String,
        path: json['path'] as String?, // may be null if inline is used
        locale: json['locale'] as String? ?? 'en',
        inline: json['inline'] == null
            ? null
            : Map<String, dynamic>.from(json['inline'] as Map),
      );
}

  factory ContentPointer.fromJson(Map<String, dynamic> json) =>
      ContentPointer(
        id: json['id'] as String,
        path: json['path'] as String,
        locale: json['locale'] as String? ?? 'en',
      );
}

/// Base interface for all content items.
abstract class ContentItem {
  ContentType get type;
  String get id;
  String get locale;
}

/// Represents an assessment story (multiple sentences).
class AssessmentStory implements ContentItem {
  @override
  final ContentType type = ContentType.assessmentStory;
  @override
  final String id;
  @override
  final String locale;
  final String title;
  final List<String> sentences;
  final List<String> targetSounds;

  AssessmentStory({
    required this.id,
    required this.locale,
    required this.title,
    required this.sentences,
    required this.targetSounds,
  });

  factory AssessmentStory.fromJson(Map<String, dynamic> json) =>
      AssessmentStory(
        id: json['id'] as String,
        locale: json['locale'] as String? ?? 'en',
        title: json['title'] as String? ?? '',
        sentences: (json['sentences'] as List? ?? const []).cast<String>(),
        targetSounds:
            (json['targetSounds'] as List? ?? const []).cast<String>(),
      );
}

/// Represents a set of sentences for practice.
class SentenceSet implements ContentItem {
  @override
  final ContentType type = ContentType.sentenceSet;
  @override
  final String id;
  @override
  final String locale;
  final List<SentenceItem> items;

  SentenceSet({
    required this.id,
    required this.locale,
    required this.items,
  });

  factory SentenceSet.fromJson(Map<String, dynamic> json) => SentenceSet(
        id: json['id'] as String,
        locale: json['locale'] as String? ?? 'en',
        items: ((json['items'] as List? ?? const [])
            .map((e) => SentenceItem.fromJson(e))
            .toList()),
      );
}

/// One sentence in a SentenceSet.
class SentenceItem {
  final String text;
  final List<String> targetSounds;
  SentenceItem({
    required this.text,
    required this.targetSounds,
  });

  factory SentenceItem.fromJson(Map<String, dynamic> json) => SentenceItem(
        text: json['text'] as String,
        targetSounds:
            (json['targetSounds'] as List? ?? const []).cast<String>(),
      );
}

/// Represents a set of words for practice.
class WordSet implements ContentItem {
  @override
  final ContentType type = ContentType.wordSet;
  @override
  final String id;
  @override
  final String locale;
  final List<WordItem> items;

  WordSet({
    required this.id,
    required this.locale,
    required this.items,
  });

  factory WordSet.fromJson(Map<String, dynamic> json) => WordSet(
        id: json['id'] as String,
        locale: json['locale'] as String? ?? 'en',
        items: ((json['items'] as List? ?? const [])
            .map((e) => WordItem.fromJson(e))
            .toList()),
      );
}

/// One word in a WordSet.
class WordItem {
  final String text;
  final List<String> targetSounds;
  WordItem({
    required this.text,
    required this.targetSounds,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) => WordItem(
        text: json['text'] as String,
        targetSounds:
            (json['targetSounds'] as List? ?? const []).cast<String>(),
      );
}

/// Parse a JSON string into the correct ContentItem subclass.
ContentItem parseContentItem(String rawJson) {
  final map = jsonDecode(rawJson) as Map<String, dynamic>;
  final type = _typeFromString(map['type'] as String);
  switch (type) {
    case ContentType.assessmentStory:
      return AssessmentStory.fromJson(map);
    case ContentType.sentenceSet:
      return SentenceSet.fromJson(map);
    case ContentType.wordSet:
      return WordSet.fromJson(map);
  }
}
