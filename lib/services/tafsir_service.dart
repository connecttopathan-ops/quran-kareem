import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Languages Al-Mukhtasar is bundled in.
///
/// Four, not the 47 of `kBundledLangs`: the Tafsir Center has published
/// Al-Mukhtasar in 31 languages but no tafsir of any kind exists in German or
/// Portuguese, so those locales fall back to English. See
/// [resolveTafsirLang].
const kTafsirLangs = {'en', 'ur-roman', 'fr', 'es', 'it'};

/// Editions that do not yet cover all 6236 verses.
///
/// The Roman Urdu edition is being translated surah by surah from the English,
/// so a verse may have no entry yet. Those fall back to English per verse
/// rather than per language — see [TafsirService.lookup].
const kTafsirPartialLangs = {'ur-roman'};

/// Stored value meaning "use whatever the Quran translation language is".
const kTafsirFollowTranslation = 'auto';

/// The language tafsir should actually be shown in.
///
/// [setting] is the stored preference — either [kTafsirFollowTranslation] or
/// a code from [kTafsirLangs]. [translationLang] is `AppState.langCode`.
/// Anything with no tafsir resolves to English rather than to an empty panel.
String resolveTafsirLang(String setting, String translationLang) {
  if (setting != kTafsirFollowTranslation && kTafsirLangs.contains(setting)) {
    return setting;
  }
  // Full code first: 'ur-roman' is itself a tafsir language, and must not be
  // reduced to 'ur', which is not.
  if (kTafsirLangs.contains(translationLang)) return translationLang;
  final base = translationLang.split('-').first;
  return kTafsirLangs.contains(base) ? base : 'en';
}

/// Per-verse tafsir text, loaded from bundled assets. No network calls.
///
/// Unlike [TranslationService], which parses one file per language, the tafsir
/// is one file per surah — 114 per language — so only the surahs actually
/// opened are parsed. A whole language is ~1.8 MB, which is worth not holding
/// in memory to show one verse.
class TafsirService extends ChangeNotifier {
  // langCode → surahNumber → verseNumber → text
  final Map<String, Map<int, Map<int, String>>> _cache = {};
  final Set<String> _loading = {};

  bool isBundled(String langCode) => kTafsirLangs.contains(langCode);

  /// Sync lookup. Null until [loadSurah] has parsed the asset, and for a
  /// verse the edition has no entry for.
  String? getText(String langCode, int surahNumber, int verseNumber) =>
      _cache[langCode]?[surahNumber]?[verseNumber];

  /// True once the asset for this surah has been parsed, successfully or not.
  bool isLoaded(String langCode, int surahNumber) =>
      _cache[langCode]?.containsKey(surahNumber) ?? false;

  bool isLoading(String langCode, int surahNumber) =>
      _loading.contains('${langCode}_$surahNumber');

  /// The tafsir to show for a verse, and which language it actually came from.
  ///
  /// Returns null only while the assets are still loading, or when neither the
  /// chosen language nor English has an entry. `lang` differs from [langCode]
  /// when a partial edition has no entry for this verse, so the caller can say
  /// so rather than silently showing English under a Roman Urdu heading.
  ({String text, String lang})? lookup(
      String langCode, int surahNumber, int verseNumber) {
    final own = getText(langCode, surahNumber, verseNumber);
    if (own != null) return (text: own, lang: langCode);
    if (langCode == 'en') return null;
    final fallback = getText('en', surahNumber, verseNumber);
    return fallback == null ? null : (text: fallback, lang: 'en');
  }

  /// Load the chosen language and, for a partial edition, English alongside it
  /// so a verse with no translation yet can fall back without a second wait.
  Future<void> loadForReading(String langCode, int surahNumber) async {
    await Future.wait([
      loadSurah(langCode, surahNumber),
      if (langCode != 'en') loadSurah('en', surahNumber),
    ]);
  }

  /// Parse `assets/tafsir/<langCode>/<surahNumber>.json` once.
  Future<void> loadSurah(String langCode, int surahNumber) async {
    if (!kTafsirLangs.contains(langCode)) return;
    if (isLoaded(langCode, surahNumber)) return;

    final key = '${langCode}_$surahNumber';
    if (_loading.contains(key)) return;
    _loading.add(key);
    notifyListeners();

    final verses = <int, String>{};
    try {
      final raw = await rootBundle
          .loadString('assets/tafsir/$langCode/$surahNumber.json');
      (jsonDecode(raw) as Map<String, dynamic>).forEach((vKey, text) {
        final v = int.tryParse(vKey);
        if (v != null && text is String && text.isNotEmpty) verses[v] = text;
      });
    } catch (_) {
      // Asset missing or malformed — cache the empty result so we don't retry
      // on every scroll, matching TranslationService.
    }

    (_cache[langCode] ??= {})[surahNumber] = verses;
    _loading.remove(key);
    notifyListeners();
  }
}
