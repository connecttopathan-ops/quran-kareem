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
          await prefs.setString('surah_cache_$surahNumber', response.body);
        }
      }
    } catch (_) {
      // Keep placeholder verses on error; user can retry by re-opening surah
    } finally {
      _loading.remove(surahNumber);
      notifyListeners();
    }
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
