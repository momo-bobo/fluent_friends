import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

/// Separate from your existing ContentRepository (sounds).
/// Loads the new content bank under assets/content/ using index.json.
/// Safe on Web/iOS/Android. If index.json is missing, methods return null.
class ContentBankRepository {
  ContentBankRepository._();
  static final ContentBankRepository instance = ContentBankRepository._();

  ContentIndex? _indexCache;
  final Map<String, ContentItem> _itemCache = {};

  Future<ContentIndex?> loadIndex() async {
    if (_indexCache != null) return _indexCache!;
    try {
      final raw = await rootBundle.loadString('assets/content/index.json');
      _indexCache = ContentIndex.fromString(raw);
      return _indexCache!;
    } catch (_) {
      // index.json not present yet or unreadable
      return null;
    }
  }

  Future<ContentItem?> loadItemByPath(String assetPath) async {
    if (_itemCache.containsKey(assetPath)) return _itemCache[assetPath]!;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final item = parseContentItem(raw);
      _itemCache[assetPath] = item;
      return item;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: get the first assessment story for a locale.
  Future<AssessmentStory?> getFirstAssessment({String locale = 'en'}) async {
    final index = await loadIndex();
    if (index == null || index.assessment.isEmpty) return null;

    // Prefer exact locale match, else first.
    final pointer = index.assessment.firstWhere(
      (p) => p.locale == locale,
      orElse: () => index.assessment.first,
    );

    final item = await loadItemByPath(pointer.path);
    return item is AssessmentStory ? item : null;
  }

  Future<SentenceSet?> getSentenceSet(String id) async {
    final index = await loadIndex();
    if (index == null) return null;
    final pointer = index.sentences.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('SentenceSet not found: $id'),
    );
    final item = await loadItemByPath(pointer.path);
    return item is SentenceSet ? item : null;
  }

  Future<WordSet?> getWordSet(String id) async {
    final index = await loadIndex();
    if (index == null) return null;
    final pointer = index.words.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('WordSet not found: $id'),
    );
    final item = await loadItemByPath(pointer.path);
    return item is WordSet ? item : null;
  }
}
