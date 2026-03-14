import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// All app language codes — every translation is bundled as a local asset.
/// No network calls are ever made for any language.
const kBundledLangs = {
  'ur-roman', 'en', 'ur', 'hi', 'ar', 'zh', 'es', 'fr', 'bn', 'pt', 'ru',
  'id', 'tr', 'fa', 'ms', 'de', 'nl', 'it', 'pl', 'sv', 'cs', 'ro', 'hu',
  'fi', 'da', 'no', 'sk', 'bg', 'hr', 'lt', 'lv', 'et', 'sl', 'el', 'sq',
  'bs', 'sr', 'uk', 'az', 'ka', 'hy', 'ta', 'th', 'ja', 'ko', 'sw', 'ml',
};

/// Manages per-verse translation text, separate from the Arabic+metadata
/// loading done by [QuranService].
///
/// All translations are bundled as local assets — zero network calls.
/// Assets load lazily on first access (with top-priority preload for the
/// 5 most common languages in the constructor).
class TranslationService extends ChangeNotifier {
  // langCode → surahNumber → verseNumber → text  (in-memory cache)
  final Map<String, Map<int, Map<int, String>>> _cache = {};

  // Tracks which (langCode_surahNumber) keys have been through loadSurahTranslation.
  final Set<String> _loaded   = {};
  final Set<String> _fetching = {};

  /// Always false — no network calls are ever made.
  bool get isDownloading => false;

  bool isBundled(String langCode) => kBundledLangs.contains(langCode);

  /// Sync lookup — returns null only until the asset has been parsed.
  String? getText(String langCode, int surahNumber, int verseNumber) =>
      _cache[langCode]?[surahNumber]?[verseNumber];

  TranslationService() {
    // Eagerly preload the 5 most common languages so getText() returns data
    // the instant the reader screen opens — no async gap, no "Loading…".
    for (final lang in const ['ur-roman', 'en', 'ur', 'hi', 'ar']) {
      unawaited(_ensureBundledLoaded(lang));
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Ensure translations for [surahNumber] in [langCode] are in [_cache].
  /// All languages load from bundled assets — this is essentially a no-op
  /// after the asset for [langCode] has been parsed once.
  Future<void> loadSurahTranslation(String langCode, int surahNumber) async {
    final key = '${langCode}_$surahNumber';
    if (_loaded.contains(key) || _fetching.contains(key)) return;
    _fetching.add(key);

    try {
      await _ensureBundledLoaded(langCode);
      _loaded.add(key);
    } finally {
      _fetching.remove(key);
    }
    notifyListeners();
  }

  // ── Bundled assets ───────────────────────────────────────────────────────────

  /// Parse the full asset file for [langCode] once and cache all surahs.
  /// Subsequent calls are instant (guarded by containsKey check).
  Future<void> _ensureBundledLoaded(String langCode) async {
    if (_cache.containsKey(langCode)) return;
    try {
      final raw = await rootBundle.loadString(
          'assets/translations/$langCode.json');
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final langMap = <int, Map<int, String>>{};
      outer.forEach((sKey, vMap) {
        final surah = int.tryParse(sKey);
        if (surah == null || vMap is! Map) return;
        final verseMap = <int, String>{};
        (vMap as Map<String, dynamic>).forEach((vKey, text) {
          final v = int.tryParse(vKey);
          if (v != null && text is String) verseMap[v] = text;
        });
        langMap[surah] = verseMap;
      });
      _cache[langCode] = langMap;
    } catch (_) {
      // Asset missing or malformed — use empty map so we don't retry.
      _cache[langCode] = {};
    }
    notifyListeners();
  }
}
