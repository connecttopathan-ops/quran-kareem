class Language {
  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRtl = false,
  });
}

const List<Language> kLanguages = [
  Language(code: 'en', name: 'English', nativeName: 'English'),
  Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', isRtl: true),
  Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', isRtl: true),
  Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
  Language(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
  Language(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
  Language(code: 'fr', name: 'French', nativeName: 'Français'),
  Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
  Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
  Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  Language(code: 'zh', name: 'Chinese', nativeName: '中文'),
  Language(code: 'fa', name: 'Persian', nativeName: 'فارسی', isRtl: true),
  Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
  Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  Language(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili'),
  Language(code: 'ha', name: 'Hausa', nativeName: 'Hausa'),
  Language(code: 'so', name: 'Somali', nativeName: 'Soomaali'),
  Language(code: 'tg', name: 'Tajik', nativeName: 'Тоҷикӣ'),
  Language(code: 'kk', name: 'Kazakh', nativeName: 'Қазақ'),
  Language(code: 'uz', name: 'Uzbek', nativeName: 'Oʻzbek'),
  Language(code: 'az', name: 'Azerbaijani', nativeName: 'Azərbaycan'),
  Language(code: 'sq', name: 'Albanian', nativeName: 'Shqip'),
  Language(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski'),
  Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
  Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
  Language(code: 'ro', name: 'Romanian', nativeName: 'Română'),
  Language(code: 'sr', name: 'Serbian', nativeName: 'Српски'),
  Language(code: 'th', name: 'Thai', nativeName: 'ภาษาไทย'),
  Language(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
  Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
  Language(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
  Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
  Language(code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
];
