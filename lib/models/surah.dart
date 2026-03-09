class VerseTranslation {
  final String transliteration;
  final String translation;
  const VerseTranslation({required this.transliteration, required this.translation});
}

class Surah {
  final int number;
  final String nameArabic;
  final String nameTransliteration;
  final String nameTranslation;
  final int verses;
  final String revelationType; // 'Meccan' or 'Medinan'
  final int juz;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameTranslation,
    required this.verses,
    required this.revelationType,
    required this.juz,
  });

  String get nameEnglish => nameTranslation;
  String get type => revelationType;
}

class Verse {
  final int number;
  final String arabic;
  final String transliteration;
  final Map<String, VerseTranslation> translations;

  const Verse({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.translations,
  });

  String translation(String langCode) =>
      translations[langCode]?.translation ?? translations['en']?.translation ?? '';
}
