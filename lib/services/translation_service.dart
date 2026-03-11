import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_service.dart';

/// The 5 languages whose translations are bundled as local assets.
/// No network calls are ever made for these — they load from rootBundle.
const kBundledLangs = {'ur-roman', 'ur', 'en', 'hi', 'ar'};

/// Manages per-verse translation text, separate from the Arabic+metadata
/// loading done by [QuranService].
///
/// * Bundled languages (ur-roman, ur, en, hi, ar): loaded eagerly at
///   construction from rootBundle — zero network, zero API calls.
/// * All other languages: checked in SharedPreferences first, then fetched
///   on demand from fawazahmed0 with a "Downloading…" banner.
class TranslationService extends ChangeNotifier {
  // langCode → surahNumber → verseNumber → text  (in-memory cache)
  final Map<String, Map<int, Map<int, String>>> _cache = {};

  // Tracks which (langCode_surahNumber) keys have been through loadSurahTranslation.
  final Set<String> _loaded   = {};
  final Set<String> _fetching = {};

  bool _isDownloading = false;

  /// True only while a first-time network fetch is running for a
  /// non-bundled language. Never true for ur-roman or other bundled langs.
  bool get isDownloading => _isDownloading;

  bool isBundled(String langCode) => kBundledLangs.contains(langCode);

  /// Sync lookup — returns null only until the asset has been parsed.
  /// For bundled langs this will be non-null almost immediately after
  /// construction (loading starts in the constructor).
  String? getText(String langCode, int surahNumber, int verseNumber) =>
      _cache[langCode]?[surahNumber]?[verseNumber];

  TranslationService() {
    // Preload ALL bundled languages immediately so getText() returns data
    // the instant the reader screen opens — no async gap, no "Loading…".
    for (final lang in kBundledLangs) {
      unawaited(_ensureBundledLoaded(lang));
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Ensure translations for [surahNumber] in [langCode] are in [_cache].
  /// For bundled langs this is essentially a no-op after construction.
  Future<void> loadSurahTranslation(String langCode, int surahNumber) async {
    final key = '${langCode}_$surahNumber';
    if (_loaded.contains(key) || _fetching.contains(key)) return;
    _fetching.add(key);

    try {
      if (isBundled(langCode)) {
        // Just ensure the full asset is parsed (usually already done).
        await _ensureBundledLoaded(langCode);
      } else {
        await _loadNonBundled(langCode, surahNumber);
      }
      _loaded.add(key);
    } finally {
      _fetching.remove(key);
    }
    notifyListeners();
  }

  // ── Bundled ──────────────────────────────────────────────────────────────────

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
    } catch (e) {
      // Asset missing or placeholder {} — use empty map so we don't retry.
      _cache[langCode] = {};
    }
    notifyListeners();
  }

  // ── Non-bundled ──────────────────────────────────────────────────────────────

  Future<void> _loadNonBundled(String langCode, int surahNumber) async {
    // 1. SharedPreferences cache (written by QuranService.downloadAllSurahs)
    final prefs = await SharedPreferences.getInstance();
    final spKey = 'translation_cache_${langCode}_$surahNumber';
    final cached = prefs.getString(spKey);
    if (cached != null) {
      _applyTextList(langCode, surahNumber,
          (jsonDecode(cached) as List).cast<String>());
      return;
    }

    // 2. Fetch from fawazahmed0 CDN (first-time only)
    final fawazEdition = QuranService.kFawazEditions[langCode];
    if (fawazEdition == null) return;

    _isDownloading = true;
    notifyListeners();
    try {
      final uri = Uri.parse(
        'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1'
        '/editions/$fawazEdition/$surahNumber.json',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chapter = data['chapter'] as List?;
        if (chapter != null) {
          final texts =
              chapter.map((v) => (v['text'] as String? ?? '')).toList();
          await prefs.setString(spKey, jsonEncode(texts));
          _applyTextList(langCode, surahNumber, texts);
        }
      }
    } catch (_) {
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  void _applyTextList(
      String langCode, int surahNumber, List<String> texts) {
    _cache[langCode] ??= {};
    _cache[langCode]![surahNumber] = {
      for (int i = 0; i < texts.length; i++) i + 1: texts[i],
    };
  }
}
