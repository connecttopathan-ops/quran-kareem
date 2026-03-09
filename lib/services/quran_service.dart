import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../data/quran_data.dart';

class QuranService extends ChangeNotifier {
  final Map<int, List<Verse>> _verses = {};
  final Set<int> _loading = {};
  // Surah 1 is fully hardcoded in quran_data.dart
  final Set<int> _loaded = {1};
  // Tracks which (surahNumber, langCode) combos have been fetched
  final Set<String> _loadedTranslations = {};

  QuranService() {
    _verses.addAll(kQuranData);
  }

  List<Verse> getVerses(int surahNumber) => _verses[surahNumber] ?? [];
  bool isLoading(int surahNumber) => _loading.contains(surahNumber);
  bool isLoaded(int surahNumber) => _loaded.contains(surahNumber);

  Future<void> loadSurah(int surahNumber) async {
    if (_loaded.contains(surahNumber) || _loading.contains(surahNumber)) return;

    // Try SharedPreferences cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('surah_cache_$surahNumber');
    if (cached != null) {
      final verses = _parseResponse(cached);
      if (verses != null) {
        _verses[surahNumber] = verses;
        _loaded.add(surahNumber);
        _loadedTranslations.add('${surahNumber}_en');
        _loadedTranslations.add('${surahNumber}_ur');
        notifyListeners();
        return;
      }
    }

    _loading.add(surahNumber);
    notifyListeners();

    try {
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/editions/'
        'quran-uthmani,en.transliteration,en.asad,ur.jalandhry',
      );
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final verses = _parseResponse(response.body);
        if (verses != null) {
          _verses[surahNumber] = verses;
          _loaded.add(surahNumber);
          _loadedTranslations.add('${surahNumber}_en');
          _loadedTranslations.add('${surahNumber}_ur');
          await prefs.setString('surah_cache_$surahNumber', response.body);
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
  Future<void> loadTranslation(int surahNumber, String langCode, String editionId) async {
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
        final response = await http.get(uri).timeout(const Duration(seconds: 15));
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
        verses[i].translations[langCode] =
            VerseTranslation(transliteration: '', translation: text);
      }
      _loadedTranslations.add(tKey);
      notifyListeners();
    } catch (_) {}
  }

  List<Verse>? _parseResponse(String body) {
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
        final translit =
            i < translitAyahs.length ? translitAyahs[i]['text'] as String : '';
        final english =
            i < englishAyahs.length ? englishAyahs[i]['text'] as String : '';
        final urdu =
            i < urduAyahs.length ? urduAyahs[i]['text'] as String : '';

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
