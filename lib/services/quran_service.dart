import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../data/quran_data.dart';

class QuranService extends ChangeNotifier {
  // alquran.cloud edition IDs (fallback)
  static const Map<String, String> kEditionIds = {
    'en':      'en.asad',
    'ur':      'ur.jalandhry',
    'ur-roman':'ur.junagarhi',
    'zh':      'zh.majian',
    'hi':      'hi.hindi',
    'es':      'es.asad',
    'fr':      'fr.hamidullah',
    'bn':      'bn.bengali',
    'pt':      'pt.elhayek',
    'ru':      'ru.kuliev',
    'id':      'id.indonesian',
    'tr':      'tr.ates',
    'fa':      'fa.ansarian',
    'ms':      'ms.basmeih',
    'ar':      'ar.muyassar',
    'de':      'de.bubenheim',
    'nl':      'nl.keyzer',
    'it':      'it.piccardo',
    'pl':      'pl.bielawskiego',
    'sv':      'sv.bernstrom',
    'no':      'no.berg',
    'da':      'da.aburida',
    'fi':      'fi.efendi',
    'cs':      'cs.hrbek',
    'sk':      'sk.hrbek',
    'hu':      'hu.simon',
    'ro':      'ro.grigore',
    'bg':      'bg.theophanov',
    'hr':      'hr.mlivo',
    'bs':      'bs.korkut',
    'sq':      'sq.nahi',
    'sr':      'sr.obic',
    'ka':      'ka.georgian',
    'hy':      'hy.armenian',
    'az':      'az.mammadaliyev',
    'uk':      'uk.culturemap',
    'ta':      'ta.tamil',
    'th':      'th.thai',
    'ja':      'ja.japanese',
    'ko':      'ko.korean',
    'sw':      'sw.barwani',
    'ml':      'ml.abdulhameed',
    'lt':      'lt.mickiewicz',
    'lv':      'lv.shakova',
    'et':      'et.tahkeem',
    'sl':      'sl.krizanic',
    'el':      'el.papadopoulos',
  };

  // fawazahmed0 CDN edition IDs (primary source)
  static const Map<String, String> kFawazEditions = {
    'en':      'eng-abdullahyusufali',
    'ur':      'urd-maududi',
    'ur-roman':'urd-maududi-la',
    'zh':      'zho-majian',
    'hi':      'hin-hindi',
    'es':      'spa-asad',
    'fr':      'fra-hamidullah',
    'bn':      'ben-bengali',
    'pt':      'por-elhayek',
    'ru':      'rus-kuliev',
    'id':      'ind-indonesian',
    'tr':      'tur-ates',
    'fa':      'per-ghomshei',
    'ms':      'msa-basmeih',
    'ar':      'ara-muyassar',
    'de':      'deu-bubenheim',
    'nl':      'nld-keyzer',
    'it':      'ita-piccardo',
    'pl':      'pol-bielawskiego',
    'sv':      'swe-bernstrom',
    'no':      'nor-berg',
    'da':      'dan-aburida',
    'fi':      'fin-efendi',
    'cs':      'ces-hrbek',
    'sk':      'slk-hrbek',
    'hu':      'hun-simon',
    'ro':      'ron-grigore',
    'bg':      'bul-theophanov',
    'hr':      'hrv-mlivo',
    'bs':      'bos-korkut',
    'sq':      'sqi-nahi',
    'sr':      'srp-obic',
    'ka':      'kat-georgian',
    'hy':      'hye-armenian',
    'az':      'aze-mammadaliyev',
    'uk':      'ukr-culturemap',
    'ta':      'tam-tamil',
    'th':      'tha-thai',
    'ja':      'jpn-japanese',
    'ko':      'kor-korean',
    'sw':      'swa-barwani',
    'ml':      'mal-abdulhameed',
    'lt':      'lit-mickiewicz',
    'lv':      'lav-shakova',
    'et':      'est-tahkeem',
    'sl':      'slv-krizanic',
    'el':      'ell-papadopoulos',
  };

  static const Duration _cacheDuration = Duration(days: 7);

  static String editionForCode(String langCode) =>
      kEditionIds[langCode] ?? 'en.asad';

  /// Shared cache key for bulk-downloaded translations.
  static String _transCacheKey(String langCode, int surahNumber) =>
      'translation_cache_${langCode}_$surahNumber';

  /// Download all 114 surahs for [langCode] and save to SharedPreferences.
  /// [onProgress] is called after each surah with (completedCount).
  Future<void> downloadAllSurahs(
    String langCode, {
    void Function(int completed)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final editionId = kEditionIds[langCode];

    for (int n = 1; n <= 114; n++) {
      try {
        List<String>? texts;

        if (langCode == 'ur-roman') {
          final uri = Uri.parse(
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1'
            '/editions/urd-maududi-la/$n.json',
          );
          final response =
              await http.get(uri).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final chapter = data['chapter'] as List?;
            if (chapter != null) {
              texts =
                  chapter.map((v) => (v['text'] as String? ?? '')).toList();
            }
          }
        } else if (editionId != null) {
          final uri = Uri.parse(
            'https://api.alquran.cloud/v1/surah/$n/$editionId',
          );
          final response =
              await http.get(uri).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final ayahs = data['data']?['ayahs'] as List?;
            if (ayahs != null) {
              texts =
                  ayahs.map((a) => (a['text'] as String? ?? '')).toList();
            }
          }
        }

        if (texts != null) {
          await prefs.setString(_transCacheKey(langCode, n), jsonEncode(texts));
        }
      } catch (_) {}

      onProgress?.call(n);
    }

    // Mark language as fully downloaded
    final downloaded = prefs.getStringList('downloaded_languages') ?? [];
    if (!downloaded.contains(langCode)) {
      downloaded.add(langCode);
      await prefs.setStringList('downloaded_languages', downloaded);
    }
  }

  /// Returns list of language codes that have been fully downloaded.
  static Future<List<String>> getDownloadedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('downloaded_languages') ?? [];
  }

  /// Delete all cached translations for [langCode].
  static Future<void> deleteLanguageCache(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    for (int n = 1; n <= 114; n++) {
      await prefs.remove(_transCacheKey(langCode, n));
    }
    final downloaded = prefs.getStringList('downloaded_languages') ?? [];
    downloaded.remove(langCode);
    await prefs.setStringList('downloaded_languages', downloaded);
  }

  final Map<int, List<Verse>> _verses = {};
  final Set<int> _loading = {};
  final Set<int> _loaded = {};
  final Set<String> _loadedTranslations = {};

  QuranService() {
    _verses.addAll(kQuranData);
  }

  List<Verse> getVerses(int surahNumber) => _verses[surahNumber] ?? [];
  bool isLoading(int surahNumber) => _loading.contains(surahNumber);
  bool isLoaded(int surahNumber) => _loaded.contains(surahNumber);

  /// Load a surah. Uses alquran.cloud 3-edition batch API for Arabic +
  /// transliteration + translation. Implements 7-day cache with background
  /// refresh and next-surah prefetch.
  Future<void> loadSurah(int surahNumber,
      {String langCode = 'en', bool prefetch = true}) async {
    if (_loading.contains(surahNumber)) return;

    // If surah Arabic data already loaded, just ensure translation is available.
    if (_loaded.contains(surahNumber)) {
      final tKey = '${surahNumber}_$langCode';
      if (!_loadedTranslations.contains(tKey)) {
        await loadTranslation(surahNumber, langCode, editionForCode(langCode));
      }
      return;
    }

    // For ur-roman: use Urdu from alquran.cloud for the batch call (Arabic +
    // transliteration + Urdu), then load Roman Urdu from fawazahmed0 separately.
    final apiLangCode = langCode == 'ur-roman' ? 'ur' : langCode;
    final editionId = editionForCode(apiLangCode);
    final prefs = await SharedPreferences.getInstance();

    final cacheKey = 'surah3_${surahNumber}_$langCode';
    final tsKey = 'surah3_ts_${surahNumber}_$langCode';
    final cachedBody = prefs.getString(cacheKey);
    final cachedTs = prefs.getInt(tsKey) ?? 0;
    final isStale = DateTime.now().millisecondsSinceEpoch - cachedTs >
        _cacheDuration.inMilliseconds;

    // ── Load from cache if available ────────────────────────────────────────
    if (cachedBody != null) {
      final verses = _parse3(cachedBody, apiLangCode);
      if (verses != null) {
        _verses[surahNumber] = verses;
        _loaded.add(surahNumber);
        _loadedTranslations.add('${surahNumber}_$apiLangCode');
        notifyListeners();

        // Load Roman Urdu (or any other missing translation) from fawazahmed0
        final tKey = '${surahNumber}_$langCode';
        if (!_loadedTranslations.contains(tKey)) {
          unawaited(
              loadTranslation(surahNumber, langCode, editionForCode(langCode)));
        }

        // Background refresh if stale
        if (isStale) {
          unawaited(_refreshSurah(surahNumber, langCode, apiLangCode,
              editionId, prefs));
        }
        if (prefetch && surahNumber < 114) {
          unawaited(loadSurah(surahNumber + 1,
              langCode: langCode, prefetch: false));
        }
        return;
      }
    }

    // ── Try legacy 4-edition cache ───────────────────────────────────────────
    if (langCode == 'en' || langCode == 'ur') {
      final oldCached = prefs.getString('surah_cache_$surahNumber');
      if (oldCached != null) {
        final verses = _parse4(oldCached);
        if (verses != null) {
          _verses[surahNumber] = verses;
          _loaded.add(surahNumber);
          _loadedTranslations.add('${surahNumber}_en');
          _loadedTranslations.add('${surahNumber}_ur');
          notifyListeners();
          return;
        }
      }
    }

    // ── Fetch from network ───────────────────────────────────────────────────
    _loading.add(surahNumber);
    notifyListeners();
    try {
      await _refreshSurah(
          surahNumber, langCode, apiLangCode, editionId, prefs);
    } finally {
      _loading.remove(surahNumber);
      notifyListeners();
    }

    // Prefetch next surah (no cascade — prefetch: false)
    if (prefetch && surahNumber < 114) {
      unawaited(
          loadSurah(surahNumber + 1, langCode: langCode, prefetch: false));
    }
  }

  /// Fetch surah from alquran.cloud and update cache + in-memory state.
  Future<void> _refreshSurah(int surahNumber, String langCode,
      String apiLangCode, String editionId, SharedPreferences prefs) async {
    try {
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/editions/'
        'quran-uthmani,en.transliteration,$editionId',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final verses = _parse3(response.body, apiLangCode);
        if (verses != null) {
          _verses[surahNumber] = verses;
          _loaded.add(surahNumber);
          _loadedTranslations.add('${surahNumber}_$apiLangCode');
          final cacheKey = 'surah3_${surahNumber}_$langCode';
          final tsKey = 'surah3_ts_${surahNumber}_$langCode';
          await prefs.setString(cacheKey, response.body);
          await prefs.setInt(
              tsKey, DateTime.now().millisecondsSinceEpoch);
          notifyListeners();

          // Load Roman Urdu or other missing translation after refresh
          final tKey = '${surahNumber}_$langCode';
          if (langCode != apiLangCode &&
              !_loadedTranslations.contains(tKey)) {
            unawaited(loadTranslation(
                surahNumber, langCode, editionForCode(langCode)));
          }
        }
      } else if (langCode != 'en') {
        // alquran.cloud failed — try fawazahmed0 for translation only
        // (Arabic data stays as placeholder until a future load succeeds)
      }
    } catch (_) {}
  }

  /// Load a specific language translation for an already-loaded surah.
  /// Tries fawazahmed0 (primary CDN) first, falls back to alquran.cloud.
  Future<void> loadTranslation(
      int surahNumber, String langCode, String editionId) async {
    final tKey = '${surahNumber}_$langCode';
    if (_loadedTranslations.contains(tKey)) return;
    if (!_loaded.contains(surahNumber)) return;

    final verses = _verses[surahNumber];
    if (verses == null || verses.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'trans_cache_$tKey';
      List<String>? texts;

      // ── Try cache (bulk-download key first, then per-request key) ──────────
      final bulkCached = prefs.getString(_transCacheKey(langCode, surahNumber));
      final cached = bulkCached ?? prefs.getString(cacheKey);
      if (cached != null) {
        texts = (jsonDecode(cached) as List).cast<String>();
      }

      // ── Try fawazahmed0 (primary) ──────────────────────────────────────────
      if (texts == null) {
        final fawazEdition = kFawazEditions[langCode];
        if (fawazEdition != null) {
          try {
            final uri = Uri.parse(
              'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1'
              '/editions/$fawazEdition/$surahNumber.json',
            );
            final response =
                await http.get(uri).timeout(const Duration(seconds: 10));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final chapter = data['chapter'] as List?;
              if (chapter != null && chapter.isNotEmpty) {
                texts = chapter
                    .map((v) => (v['text'] as String? ?? ''))
                    .toList();
                await prefs.setString(cacheKey, jsonEncode(texts));
              }
            }
          } catch (_) {}
        }
      }

      // ── Fall back to alquran.cloud ─────────────────────────────────────────
      // ur-roman must only come from the fawazahmed0 Latin-script edition;
      // never fall back to a Urdu-script edition.
      if (texts == null && langCode == 'ur-roman') return;

      if (texts == null) {
        final uri = Uri.parse(
          'https://api.alquran.cloud/v1/surah/$surahNumber/editions/'
          '$editionId',
        );
        final response =
            await http.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final editions = json['data'] as List;
          if (editions.isNotEmpty) {
            final ayahs = editions[0]['ayahs'] as List;
            texts =
                ayahs.map((a) => (a['text'] as String? ?? '')).toList();
            await prefs.setString(cacheKey, jsonEncode(texts));
          }
        }
      }

      if (texts == null) return;

      for (int i = 0; i < verses.length && i < texts.length; i++) {
        verses[i].translations[langCode] = VerseTranslation(
          transliteration: verses[i].transliteration,
          translation: texts[i],
        );
      }
      _loadedTranslations.add(tKey);
      notifyListeners();
    } catch (_) {}
  }

  // ── Parsers ─────────────────────────────────────────────────────────────────

  /// Parse a 3-edition API response (Arabic, transliteration, language).
  List<Verse>? _parse3(String body, String langCode) {
    try {
      final json = jsonDecode(body);
      final editions = json['data'] as List;
      if (editions.length < 3) return null;

      final arabicAyahs = editions[0]['ayahs'] as List;
      final translitAyahs = editions[1]['ayahs'] as List;
      final langAyahs = editions[2]['ayahs'] as List;

      return List.generate(arabicAyahs.length, (i) {
        final num = arabicAyahs[i]['numberInSurah'] as int;
        final arabic = arabicAyahs[i]['text'] as String;
        final translit = i < translitAyahs.length
            ? translitAyahs[i]['text'] as String
            : '';
        final langText =
            i < langAyahs.length ? langAyahs[i]['text'] as String : '';

        return Verse(
          number: num,
          arabic: arabic,
          transliteration: translit,
          translations: {
            langCode: VerseTranslation(
                transliteration: translit, translation: langText),
            // Always keep an 'en' entry so fallback in _VerseCard works.
            if (langCode != 'en')
              'en':
                  VerseTranslation(transliteration: translit, translation: ''),
          },
        );
      });
    } catch (_) {
      return null;
    }
  }

  /// Parse a legacy 4-edition API response (Arabic, translit, English, Urdu).
  List<Verse>? _parse4(String body) {
    try {
      final json = jsonDecode(body);
      final editions = json['data'] as List;
      if (editions.length < 4) return null;

      final arabicAyahs = editions[0]['ayahs'] as List;
      final translitAyahs = editions[1]['ayahs'] as List;
      final englishAyahs = editions[2]['ayahs'] as List;
      final urduAyahs = editions[3]['ayahs'] as List;

      return List.generate(arabicAyahs.length, (i) {
        final num = arabicAyahs[i]['numberInSurah'] as int;
        final arabic = arabicAyahs[i]['text'] as String;
        final translit = i < translitAyahs.length
            ? translitAyahs[i]['text'] as String
            : '';
        final english = i < englishAyahs.length
            ? englishAyahs[i]['text'] as String
            : '';
        final urdu =
            i < urduAyahs.length ? urduAyahs[i]['text'] as String : '';

        return Verse(
          number: num,
          arabic: arabic,
          transliteration: translit,
          translations: {
            'en': VerseTranslation(
                transliteration: translit, translation: english),
            'ur': VerseTranslation(
                transliteration: translit, translation: urdu),
          },
        );
      });
    } catch (_) {
      return null;
    }
  }
}
