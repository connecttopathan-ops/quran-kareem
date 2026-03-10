class Language {
  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;
  final String editionId;
  final String group;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.editionId,
    this.isRtl = false,
    this.group = 'Global',
  });
}

const List<Language> kLanguages = [
  // ── GLOBAL ────────────────────────────────────────────────────────────────
  Language(code: 'en',       name: 'English',     nativeName: 'English',          editionId: 'en.asad',          group: 'Global'),
  Language(code: 'zh',       name: 'Chinese',     nativeName: '中文',              editionId: 'zh.majian',        group: 'Global'),
  Language(code: 'hi',       name: 'Hindi',       nativeName: 'हिन्दी',            editionId: 'hi.hindi',         group: 'Global'),
  Language(code: 'es',       name: 'Spanish',     nativeName: 'Español',           editionId: 'es.asad',          group: 'Global'),
  Language(code: 'ar',       name: 'Arabic',      nativeName: 'العربية',           editionId: 'ar.muyassar',      isRtl: true, group: 'Global'),
  Language(code: 'fr',       name: 'French',      nativeName: 'Français',          editionId: 'fr.hamidullah',    group: 'Global'),
  Language(code: 'bn',       name: 'Bengali',     nativeName: 'বাংলা',             editionId: 'bn.bengali',       group: 'Global'),
  Language(code: 'pt',       name: 'Portuguese',  nativeName: 'Português',         editionId: 'pt.elhayek',       group: 'Global'),
  Language(code: 'ru',       name: 'Russian',     nativeName: 'Русский',           editionId: 'ru.kuliev',        group: 'Global'),
  Language(code: 'id',       name: 'Indonesian',  nativeName: 'Bahasa Indonesia',  editionId: 'id.indonesian',    group: 'Global'),
  Language(code: 'ur',       name: 'Urdu',        nativeName: 'اردو',              editionId: 'ur.jalandhry',     isRtl: true, group: 'Global'),
  Language(code: 'tr',       name: 'Turkish',     nativeName: 'Türkçe',            editionId: 'tr.ates',          group: 'Global'),
  Language(code: 'fa',       name: 'Persian',     nativeName: 'فارسی',             editionId: 'fa.ansarian',      isRtl: true, group: 'Global'),
  Language(code: 'ms',       name: 'Malay',       nativeName: 'Bahasa Melayu',     editionId: 'ms.basmeih',       group: 'Global'),
  Language(code: 'ur-roman', name: 'Roman Urdu',  nativeName: 'Roman Urdu',        editionId: 'ur.junagarhi',     group: 'Global'),

  // ── EUROPE ────────────────────────────────────────────────────────────────
  Language(code: 'de',       name: 'German',      nativeName: 'Deutsch',           editionId: 'de.bubenheim',     group: 'Europe'),
  Language(code: 'nl',       name: 'Dutch',       nativeName: 'Nederlands',        editionId: 'nl.keyzer',        group: 'Europe'),
  Language(code: 'it',       name: 'Italian',     nativeName: 'Italiano',          editionId: 'it.piccardo',      group: 'Europe'),
  Language(code: 'pl',       name: 'Polish',      nativeName: 'Polski',            editionId: 'pl.bielawskiego',  group: 'Europe'),
  Language(code: 'sv',       name: 'Swedish',     nativeName: 'Svenska',           editionId: 'sv.bernstrom',     group: 'Europe'),
  Language(code: 'cs',       name: 'Czech',       nativeName: 'Čeština',           editionId: 'cs.hrbek',         group: 'Europe'),
  Language(code: 'ro',       name: 'Romanian',    nativeName: 'Română',            editionId: 'ro.grigore',       group: 'Europe'),
  Language(code: 'hu',       name: 'Hungarian',   nativeName: 'Magyar',            editionId: 'hu.simon',         group: 'Europe'),
  Language(code: 'fi',       name: 'Finnish',     nativeName: 'Suomi',             editionId: 'fi.efendi',        group: 'Europe'),
  Language(code: 'da',       name: 'Danish',      nativeName: 'Dansk',             editionId: 'da.aburida',       group: 'Europe'),
  Language(code: 'no',       name: 'Norwegian',   nativeName: 'Norsk',             editionId: 'no.berg',          group: 'Europe'),
  Language(code: 'sk',       name: 'Slovak',      nativeName: 'Slovenčina',        editionId: 'sk.hrbek',         group: 'Europe'),
  Language(code: 'bg',       name: 'Bulgarian',   nativeName: 'Български',         editionId: 'bg.theophanov',    group: 'Europe'),
  Language(code: 'hr',       name: 'Croatian',    nativeName: 'Hrvatski',          editionId: 'hr.mlivo',         group: 'Europe'),
  Language(code: 'lt',       name: 'Lithuanian',  nativeName: 'Lietuvių',          editionId: 'lt.mickiewicz',    group: 'Europe'),
  Language(code: 'lv',       name: 'Latvian',     nativeName: 'Latviešu',          editionId: 'lv.shakova',       group: 'Europe'),
  Language(code: 'et',       name: 'Estonian',    nativeName: 'Eesti',             editionId: 'et.tahkeem',       group: 'Europe'),
  Language(code: 'sl',       name: 'Slovenian',   nativeName: 'Slovenščina',       editionId: 'sl.krizanic',      group: 'Europe'),
  Language(code: 'el',       name: 'Greek',       nativeName: 'Ελληνικά',          editionId: 'el.papadopoulos',  group: 'Europe'),
  Language(code: 'sq',       name: 'Albanian',    nativeName: 'Shqip',             editionId: 'sq.nahi',          group: 'Europe'),
  Language(code: 'bs',       name: 'Bosnian',     nativeName: 'Bosanski',          editionId: 'bs.korkut',        group: 'Europe'),
  Language(code: 'sr',       name: 'Serbian',     nativeName: 'Српски',            editionId: 'sr.obic',          group: 'Europe'),
  Language(code: 'uk',       name: 'Ukrainian',   nativeName: 'Українська',        editionId: 'uk.culturemap',    group: 'Europe'),
  Language(code: 'az',       name: 'Azerbaijani', nativeName: 'Azərbaycan',        editionId: 'az.mammadaliyev',  group: 'Europe'),
  Language(code: 'ka',       name: 'Georgian',    nativeName: 'ქართული',           editionId: 'ka.georgian',      group: 'Europe'),
  Language(code: 'hy',       name: 'Armenian',    nativeName: 'Հայերեն',           editionId: 'hy.armenian',      group: 'Europe'),

  // ── ASIA / AFRICA ─────────────────────────────────────────────────────────
  Language(code: 'ta',       name: 'Tamil',       nativeName: 'தமிழ்',             editionId: 'ta.tamil',         group: 'Asia/Africa'),
  Language(code: 'th',       name: 'Thai',        nativeName: 'ภาษาไทย',           editionId: 'th.thai',          group: 'Asia/Africa'),
  Language(code: 'ja',       name: 'Japanese',    nativeName: '日本語',             editionId: 'ja.japanese',      group: 'Asia/Africa'),
  Language(code: 'ko',       name: 'Korean',      nativeName: '한국어',             editionId: 'ko.korean',        group: 'Asia/Africa'),
  Language(code: 'sw',       name: 'Swahili',     nativeName: 'Kiswahili',         editionId: 'sw.barwani',       group: 'Asia/Africa'),
];
