import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../data/quran_data.dart';

class QuranService extends ChangeNotifier {
  // Complete mapping of all supported language codes → Quran API edition IDs.
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

  static String editionForCode(String langCode) =>
      kEditionIds[langCode] ?? 'en.asad';

  final Map<int, List<Verse>> _verses = {};
  final Set<int> _loading = {};
  // Surah 1 is fully hardcoded in quran_data.dart
  final Set<int> _loaded = {1};
  // Tracks which (surahNumber, langCode) combos have been fetched
  final Set<String> _loadedTranslations = {};

  QuranService() {
    _verses.addAll(kQuranData);
    _loadedTranslations.add('1_en');
    _loadedTranslations.add('1_ur');
  }

  List<Verse> getVerses(int surahNumber) => _verses[surahNumber] ?? [];
  bool isLoading(int surahNumber) => _loading.contains(surahNumber);
  bool isLoaded(int surahNumber) => _loaded.contains(surahNumber);

  /// Load a surah, fetching Arabic + transliteration + the user's chosen
  /// language translation in a single 3-edition API call.
  Future<void> loadSurah(int surahNumber, {String langCode = 'en'}) async {
    if (_loading.contains(surahNumber)) return;

    // If surah is already loaded, just ensure the requested lang is available.
    if (_loaded.contains(surahNumber)) {
      final tKey = '${surahNumber}_$langCode';
      if (!_loadedTranslations.contains(tKey)) {
        await loadTranslation(surahNumber, langCode, editionForCode(langCode));
      }
      return;
    }

    final editionId = editionForCode(langCode);
    final prefs = await SharedPreferences.getInstance();

    // ── Try new-format 3-edition cache ──────────────────────────────────────
    final newCacheKey = 'surah3_${surahNumber}_$langCode';
    final newCached = prefs.getString(newCacheKey);
    if (newCached != null) {
      final verses = _parse3(newCached, langCode);
      if (verses != null) {
        _verses[surahNumber] = verses;
        _loaded.add(surahNumber);
        _loadedTranslations.add('${surahNumber}_$langCode');
        notifyListeners();
        return;
      }
    }

    // ── Try legacy 4-edition cache (for users upgrading from older builds) ──
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

    // ── Fetch from API ───────────────────────────────────────────────────────
    _loading.add(surahNumber);
    notifyListeners();

    try {
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/editions/'
        'quran-uthmani,en.transliteration,$editionId',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final verses = _parse3(response.body, langCode);
        if (verses != null) {
          _verses[surahNumber] = verses;
          _loaded.add(surahNumber);
          _loadedTranslations.add('${surahNumber}_$langCode');
          await prefs.setString(newCacheKey, response.body);
        }
      } else {
        // API returned an error — fall back to English if possible
        if (langCode != 'en') {
          await loadSurah(surahNumber, langCode: 'en');
        }
      }
    } catch (_) {
      // Keep placeholder verses on error
    } finally {
      _loading.remove(surahNumber);
      notifyListeners();
    }
  }

  /// Load a specific language translation for an already-loaded surah.
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
      List? ayahs;

      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        ayahs = jsonDecode(cached) as List?;
      } else {
        final uri = Uri.parse(
          'https://api.alquran.cloud/v1/surah/$surahNumber/editions/$editionId',
        );
        final response =
            await http.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final editions = json['data'] as List;
          if (editions.isNotEmpty) {
            ayahs = editions[0]['ayahs'] as List;
            await prefs.setString(cacheKey, jsonEncode(ayahs));
          }
        }
      }

      if (ayahs == null) return;

      for (int i = 0; i < verses.length && i < ayahs.length; i++) {
        final text = ayahs[i]['text'] as String? ?? '';
        // Store with the verse's own transliteration so it's always available
        verses[i].translations[langCode] = VerseTranslation(
          transliteration: verses[i].transliteration,
          translation: text,
        );
      }
      _loadedTranslations.add(tKey);
      notifyListeners();
    } catch (_) {}
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  /// Parse a 3-edition API response (Arabic, transliteration, language).
  List<Verse>? _parse3(String body, String langCode) {
    try {
      final json = jsonDecode(body);
      final editions = json['data'] as List;
      if (editions.length < 3) return null;

      final arabicAyahs   = editions[0]['ayahs'] as List;
      final translitAyahs = editions[1]['ayahs'] as List;
      final langAyahs     = editions[2]['ayahs'] as List;

      return List.generate(arabicAyahs.length, (i) {
        final num      = arabicAyahs[i]['numberInSurah'] as int;
        final arabic   = arabicAyahs[i]['text'] as String;
        final translit = i < translitAyahs.length
            ? translitAyahs[i]['text'] as String
            : '';
        final langText = i < langAyahs.length
            ? langAyahs[i]['text'] as String
            : '';

        return Verse(
          number: num,
          arabic: arabic,
          transliteration: translit,
          translations: {
            langCode: VerseTranslation(
                transliteration: translit, translation: langText),
            // Always keep an 'en' entry (translit only) so the fallback
            // in _VerseCard doesn't blank out transliteration.
            if (langCode != 'en')
              'en': VerseTranslation(transliteration: translit, translation: ''),
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

      final arabicAyahs   = editions[0]['ayahs'] as List;
      final translitAyahs = editions[1]['ayahs'] as List;
      final englishAyahs  = editions[2]['ayahs'] as List;
      final urduAyahs     = editions[3]['ayahs'] as List;

      return List.generate(arabicAyahs.length, (i) {
        final num      = arabicAyahs[i]['numberInSurah'] as int;
        final arabic   = arabicAyahs[i]['text'] as String;
        final translit = i < translitAyahs.length
            ? translitAyahs[i]['text'] as String
            : '';
        final english  = i < englishAyahs.length
            ? englishAyahs[i]['text'] as String
            : '';
        final urdu     = i < urduAyahs.length
            ? urduAyahs[i]['text'] as String
            : '';

        return Verse(
          number: num,
          arabic: arabic,
          transliteration: translit,
          translations: {
            'en': VerseTranslation(transliteration: translit, translation: english),
            'ur': VerseTranslation(transliteration: translit, translation: urdu),
          },
        );
      });
    } catch (_) {
      return null;
    }
  }
}
