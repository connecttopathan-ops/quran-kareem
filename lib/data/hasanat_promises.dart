// Quran and authentic hadeeth promises related to charity (sadaqah).
// Numbers shown in the UI are read directly from these texts — they are
// Allah's promise, not the app's calculation.
//
// Multipliers are only used where the text explicitly states a numerical
// reward. We never stack multipliers (e.g. 700x × Ramadan), since no text
// supports that combination.

class HasanatPromise {
  final String sourceType; // 'quran' or 'hadeeth'
  final String? arabic;
  final String translation;
  final String source;
  final String? highlight; // phrase to emphasise inside the translation

  const HasanatPromise({
    required this.sourceType,
    this.arabic,
    required this.translation,
    required this.source,
    this.highlight,
  });
}

class DeedCategory {
  final String key;
  final String label;
  final List<HasanatPromise> promises;
  final List<String> conditions;
  // Multipliers are optional. When both are present we show two footnote
  // rows ("Minimum (per X)" and "Up to (per Y)"). When only one is set we
  // show a single row.
  final int? minMultiplier;
  final String? minSource;
  final int? maxMultiplier;
  final String? maxSource;

  const DeedCategory({
    required this.key,
    required this.label,
    required this.promises,
    required this.conditions,
    this.minMultiplier,
    this.minSource,
    this.maxMultiplier,
    this.maxSource,
  });
}

const _verse2_261 = HasanatPromise(
  sourceType: 'quran',
  arabic:
      'مَّثَلُ ٱلَّذِينَ يُنفِقُونَ أَمْوَٰلَهُمْ فِى سَبِيلِ ٱللَّهِ كَمَثَلِ حَبَّةٍ أَنۢبَتَتْ سَبْعَ سَنَابِلَ فِى كُلِّ سُنۢبُلَةٍ مِّا۟ئَةُ حَبَّةٍ',
  translation:
      '"The example of those who spend their wealth in the way of Allah is like a seed that sprouts seven ears, in each ear one hundred grains. And Allah multiplies for whom He wills."',
  source: 'Surah Al-Baqarah 2:261',
  highlight: 'one hundred grains',
);

const _verse6_160 = HasanatPromise(
  sourceType: 'quran',
  arabic: 'مَن جَآءَ بِٱلْحَسَنَةِ فَلَهُۥ عَشْرُ أَمْثَالِهَا',
  translation:
      '"Whoever comes with a good deed will have ten times the like thereof."',
  source: 'Surah Al-An\'am 6:160',
  highlight: 'ten times the like thereof',
);

const _hadeethJariyah = HasanatPromise(
  sourceType: 'hadeeth',
  translation:
      '"When a person dies, all their deeds cease except three: a sadaqah jariyah, beneficial knowledge, or a righteous child who prays for them."',
  source: 'Sahih Muslim 1631',
  highlight: 'sadaqah jariyah',
);

const _verse76_8_9 = HasanatPromise(
  sourceType: 'quran',
  arabic:
      'وَيُطْعِمُونَ ٱلطَّعَامَ عَلَىٰ حُبِّهِۦ مِسْكِينًا وَيَتِيمًا وَأَسِيرًا • إِنَّمَا نُطْعِمُكُمْ لِوَجْهِ ٱللَّهِ لَا نُرِيدُ مِنكُمْ جَزَآءً وَلَا شُكُورًا',
  translation:
      '"And they give food, in spite of their love for it, to the poor, the orphan, and the captive, [saying] we feed you only for the Face of Allah; we wish neither reward nor thanks from you."',
  source: 'Surah Al-Insan 76:8–9',
);

const _hadeethMasjid = HasanatPromise(
  sourceType: 'hadeeth',
  translation:
      '"Whoever builds a masjid for the sake of Allah, Allah will build for him a house like it in Paradise."',
  source: 'Sahih al-Bukhari 450',
);

const _commonSadaqahConditions = [
  'Sincere intention (ikhlas) — for the sake of Allah alone',
  'Wealth from a halal source',
  'Given without reminder of favour or harm (Quran 2:262)',
];

const sadaqahCategories = <DeedCategory>[
  DeedCategory(
    key: 'general',
    label: 'Sadaqah',
    promises: [_verse2_261, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'jariyah',
    label: 'Sadaqah Jariyah',
    promises: [_hadeethJariyah, _verse2_261],
    conditions: [
      ..._commonSadaqahConditions,
      'A lasting benefit (e.g. a well, a Quran, beneficial knowledge)',
    ],
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'feeding',
    label: 'Feeding the Poor',
    promises: [_verse76_8_9, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'masjid',
    label: 'Masjid / Orphans',
    promises: [_hadeethMasjid, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
  ),
];
