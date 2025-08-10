import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

/// Loads the new JSON content bank under assets/content/ using index.json.
/// Separate from your existing ContentRepository (sounds).
class ContentBankRepository {
  ContentBankRepository._();
  static final ContentBankRepository instance = ContentBankRepository._();

  ContentIndex? _indexCache;
  final Map<String, ContentItem> _itemCache = {};

  Future<ContentIndex?> loadIndex() async {
    if (_indexCache != null) return _indexCache!;
    try {
      debugPrint('[ContentBank] Loading assets/content/index.json …');
      final raw = await rootBundle.loadString('assets/content/index.json');
      _indexCache = ContentIndex.fromString(raw);
      debugPrint(
        '[ContentBank] Index loaded: '
        'assessment=${_indexCache!.assessment.length}, '
        'sentences=${_indexCache!.sentences.length}, '
        'words=${_indexCache!.words.length}',
      );
      return _indexCache!;
    } catch (e) {
      debugPrint('[ContentBank] Failed to load index.json: $e');
      return null;
    }
  }

  Future<ContentItem?> loadItemByPath(String assetPath) async {
    if (_itemCache.containsKey(assetPath)) return _itemCache[assetPath]!;
    try {
      debugPrint('[ContentBank] Loading item: $assetPath');
      final raw = await rootBundle.loadString(assetPath);
      final item = parseContentItem(raw);
      _itemCache[assetPath] = item;
      debugPrint('[ContentBank] Loaded item runtimeType=${item.runtimeType}');
      return item;
    } catch (e) {
      debugPrint('[ContentBank] Failed to load item $assetPath: $e');
      return null;
    }
  }

  /// Convenience: first assessment story for a locale (default 'en').
  Future<AssessmentStory?> getFirstAssessment({String locale = 'en'}) async {
    final index = await loadIndex();
    if (index == null || index.assessment.isEmpty) {
      debugPrint('[ContentBank] No assessment entries in index.');
      return null;
    }

    final pointer = index.assessment.firstWhere(
      (p) => p.locale == locale,
      orElse: () => index.assessment.first,
    );

    // First, try inline if present
    if (pointer.inline != null) {
      try {
        final item = AssessmentStory.fromJson(pointer.inline!);
        debugPrint('[ContentBank] Loaded assessment from inline with ${item.sentences.length} sentences.');
        return item;
      } catch (e) {
        debugPrint('[ContentBank] Failed to parse inline assessment: $e');
        // fall through to path
      }
    }

    // Otherwise, load from asset path as before
    if (pointer.path == null) {
      debugPrint('[ContentBank] No path for assessment and no inline data.');
      return null;
    }

    debugPrint('[ContentBank] Using assessment: id=${pointer.id} path=${pointer.path}');
    final item = await loadItemByPath(pointer.path!);
    if (item is! AssessmentStory) {
      debugPrint('[ContentBank] Loaded item is not an AssessmentStory.');
      return null;
    }
    debugPrint('[ContentBank] Assessment story loaded with ${item.sentences.length} sentences.');
    return item;
  }

  Future<SentenceSet?> getSentenceSet(String id) async {
    final index = await loadIndex();
    if (index == null) return null;

    try {
      final pointer = index.sentences.firstWhere((p) => p.id == id);
      final item = await loadItemByPath(pointer.path);
      return item is SentenceSet ? item : null;
    } catch (e) {
      debugPrint('[ContentBank] SentenceSet not found: $id ($e)');
      return null;
    }
  }

  Future<WordSet?> getWordSet(String id) async {
    final index = await loadIndex();
    if (index == null) return null;

    try {
      final pointer = index.words.firstWhere((p) => p.id == id);
      final item = await loadItemByPath(pointer.path);
      return item is WordSet ? item : null;
    } catch (e) {
      debugPrint('[ContentBank] WordSet not found: $id ($e)');
      return null;
    }
  }

  /// Clears caches (useful in hot reload debugging).
  void resetCachesForDebug() {
    _indexCache = null;
    _itemCache.clear();
  }
}
