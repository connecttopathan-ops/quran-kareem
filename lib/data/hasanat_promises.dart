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

  /// The passage, by language code. `'en'` is always present and is the
  /// fallback.
  ///
  /// Held beside the Arabic rather than in the ARB so a reviewer can check
  /// one passage in one place. These are Quran and hadith, not product copy.
  final Map<String, String> translations;

  /// Citation — never translated; the numerals and reference form are fixed.
  final String source;

  /// Phrase to emphasise inside the translation, by language code.
  ///
  /// The UI finds this as a *substring* of the rendered translation, so each
  /// language's highlight must be copied out of that same language's
  /// translation character-for-character. Translate the two independently and
  /// the match silently fails — no error, just no emphasis.
  final Map<String, String>? highlights;

  const HasanatPromise({
    required this.sourceType,
    this.arabic,
    required this.translations,
    required this.source,
    this.highlights,
  });

  /// The passage in [languageCode], falling back to English.
  String translation(String languageCode) =>
      translations[languageCode] ?? translations['en'] ?? '';

  /// The emphasised phrase in [languageCode], or null if this passage has
  /// none. Falls back to English only when the English translation is also
  /// being shown, since a highlight from one language cannot be found inside
  /// another language's text.
  String? highlight(String languageCode) {
    if (highlights == null) return null;
    final exact = highlights![languageCode];
    if (exact != null) return exact;
    return translations.containsKey(languageCode) ? null : highlights!['en'];
  }
}

class DeedCategory {
  final String key;

  /// Category name, by language code. `'en'` is the fallback.
  final Map<String, String> labels;

  final List<HasanatPromise> promises;

  /// Conditions for the reward, one locale map per condition.
  ///
  /// A list of maps rather than a map of lists so each condition's six
  /// renderings stay together — the same reason the Names keep theirs on the
  /// entry. Adding a condition is then one entry, not an edit in six places.
  final List<Map<String, String>> conditions;
  // Multipliers are optional. When both are present we show two footnote
  // rows ("Minimum (per X)" and "Up to (per Y)"). When only one is set we
  // show a single row.
  final int? minMultiplier;
  final String? minSource;
  final int? maxMultiplier;
  final String? maxSource;

  const DeedCategory({
    required this.key,
    required this.labels,
    required this.promises,
    required this.conditions,
    this.minMultiplier,
    this.minSource,
    this.maxMultiplier,
    this.maxSource,
  });

  /// The category name in [languageCode], falling back to English.
  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? '';

  /// The conditions in [languageCode], each falling back to English.
  List<String> conditionsFor(String languageCode) => [
        for (final c in conditions) c[languageCode] ?? c['en'] ?? '',
      ];
}

const _verse2_261 = HasanatPromise(
  sourceType: 'quran',
  arabic:
      'مَّثَلُ ٱلَّذِينَ يُنفِقُونَ أَمْوَٰلَهُمْ فِى سَبِيلِ ٱللَّهِ كَمَثَلِ حَبَّةٍ أَنۢبَتَتْ سَبْعَ سَنَابِلَ فِى كُلِّ سُنۢبُلَةٍ مِّا۟ئَةُ حَبَّةٍ',
  translations: {
    'en': '"The example of those who spend their wealth in the way of Allah is like a seed that sprouts seven ears, in each ear one hundred grains. And Allah multiplies for whom He wills."',
    'fr': '"Ceux qui dépensent leurs biens dans le sentier d\'Allah ressemblent à un grain qui produit sept épis, à cent grains l\'épi. Et Allah multiplie la récompense à qui Il veut."',
    'es': '"El ejemplo de quienes contribuyen con su riqueza por la causa de Allah es como el de una semilla que germina dando siete espigas, y en cada espiga hay cien granos. Y Allah multiplica a quien Él quiere."',
    'it': '"Quelli che con i loro beni sono generosi per la causa di Allah, sono come un seme da cui nascono sette spighe e in ogni spiga ci sono cento semi. Allah moltiplica il merito a chi vuole."',
    'de': '"Das Gleichnis derjenigen, die ihren Besitz auf Allahs Weg ausgeben, ist das eines Saatkorns, das sieben Ähren wachsen läßt, in jeder Ähre hundert Körner. Allah gibt Vielfaches, wem Er will."',
    'pt': '"O exemplo daqueles que despendem os seus bens pela causa de Allah assemelha-se ao de um grão que germina sete espigas, contendo cada uma cem grãos. E Allah multiplica a quem Lhe apraz."',
  },
  source: 'Surah Al-Baqarah 2:261',
  highlights: {
    'en': 'one hundred grains',
    'fr': 'cent grains',
    'es': 'cien granos',
    'it': 'cento semi',
    'de': 'hundert Körner',
    'pt': 'cem grãos',
  },
);

const _verse6_160 = HasanatPromise(
  sourceType: 'quran',
  arabic: 'مَن جَآءَ بِٱلْحَسَنَةِ فَلَهُۥ عَشْرُ أَمْثَالِهَا',
  translations: {
    'en': '"Whoever comes with a good deed will have ten times the like thereof."',
    'fr': '"Quiconque fait une bonne action, il lui en sera attribué dix fois autant."',
    'es': '"Quien presente una buena obra, recibirá diez veces otro tanto."',
    'it': '"Chi farà un bene, ne avrà dieci volte tanto."',
    'de': '"Wer eine gute Tat vollbringt, dem wird sie zehnfach vergolten."',
    'pt': '"Quem tiver praticado uma boa ação receberá dez vezes mais."',
  },
  source: 'Surah Al-An\'am 6:160',
  highlights: {
    'en': 'ten times the like thereof',
    'fr': 'dix fois autant',
    'es': 'diez veces otro tanto',
    'it': 'dieci volte tanto',
    'de': 'zehnfach vergolten',
    'pt': 'dez vezes mais',
  },
);

const _hadeethJariyah = HasanatPromise(
  sourceType: 'hadeeth',
  translations: {
    'en': '"When a person dies, all their deeds cease except three: a sadaqah jariyah, beneficial knowledge, or a righteous child who prays for them."',
    'fr': '"Lorsqu\'une personne meurt, toutes ses œuvres cessent, sauf trois : une sadaqah jariyah, une science bénéfique, ou un enfant pieux qui invoque Allah pour elle."',
    'es': '"Cuando una persona muere, todas sus obras cesan excepto tres: una sadaqah jariyah, un conocimiento beneficioso, o un hijo piadoso que suplica por ella."',
    'it': '"Quando una persona muore, tutte le sue opere cessano tranne tre: una sadaqah jariyah, una conoscenza benefica, o un figlio pio che prega per lei."',
    'de': '"Wenn ein Mensch stirbt, enden alle seine Taten außer drei: eine sadaqah jariyah, nützliches Wissen oder ein rechtschaffenes Kind, das für ihn betet."',
    'pt': '"Quando uma pessoa morre, todas as suas obras cessam, exceto três: uma sadaqah jariyah, um conhecimento benéfico, ou um filho piedoso que suplica por ela."',
  },
  source: 'Sahih Muslim 1631',
  highlights: {
    'en': 'sadaqah jariyah',
    'fr': 'sadaqah jariyah',
    'es': 'sadaqah jariyah',
    'it': 'sadaqah jariyah',
    'de': 'sadaqah jariyah',
    'pt': 'sadaqah jariyah',
  },
);

const _verse76_8_9 = HasanatPromise(
  sourceType: 'quran',
  arabic:
      'وَيُطْعِمُونَ ٱلطَّعَامَ عَلَىٰ حُبِّهِۦ مِسْكِينًا وَيَتِيمًا وَأَسِيرًا • إِنَّمَا نُطْعِمُكُمْ لِوَجْهِ ٱللَّهِ لَا نُرِيدُ مِنكُمْ جَزَآءً وَلَا شُكُورًا',
  translations: {
    'en': '"And they give food, in spite of their love for it, to the poor, the orphan, and the captive, [saying] we feed you only for the Face of Allah; we wish neither reward nor thanks from you."',
    'fr': '"Et ils offrent la nourriture, malgré leur propre désir, au pauvre, à l\'orphelin et au prisonnier, [disant] : c\'est pour le visage d\'Allah que nous vous nourrissons ; nous ne voulons de vous ni récompense ni gratitude."',
    'es': '"Y dan de comer, a pesar de su amor por ella, al pobre, al huérfano y al cautivo, [diciendo] os damos de comer solamente por el Rostro de Allah; no deseamos de vosotros ni recompensa ni agradecimiento."',
    'it': '"E danno il cibo, nonostante il loro amore per esso, al povero, all\'orfano e al prigioniero, [dicendo] vi nutriamo solo per il volto di Allah; non vogliamo da voi né ricompensa né gratitudine."',
    'de': '"Und sie geben Speise, obwohl sie selbst Verlangen danach haben, dem Armen, der Waise und dem Gefangenen, [und sagen] wir speisen euch nur um Allahs Angesicht willen; wir wollen von euch weder Lohn noch Dank."',
    'pt': '"E dão de comer, apesar do seu apreço por ela, ao pobre, ao órfão e ao cativo, [dizendo] alimentamo-vos somente pela face de Allah; não desejamos de vós nem recompensa nem agradecimento."',
  },
  source: 'Surah Al-Insan 76:8–9',
);

const _hadeethMasjid = HasanatPromise(
  sourceType: 'hadeeth',
  translations: {
    'en': '"Whoever builds a masjid for the sake of Allah, Allah will build for him a house like it in Paradise."',
    'fr': '"Quiconque construit un masjid pour Allah, Allah lui construira au Paradis une maison semblable."',
    'es': '"Quien construya un masjid por Allah, Allah le construirá una casa semejante en el Paraíso."',
    'it': '"Chi costruisce un masjid per Allah, Allah gli costruirà una casa simile in Paradiso."',
    'de': '"Wer eine Masjid um Allahs willen baut, dem wird Allah ein gleiches Haus im Paradies bauen."',
    'pt': '"Quem construir um masjid por Allah, Allah lhe construirá uma casa semelhante no Paraíso."',
  },
  source: 'Sahih al-Bukhari 450',
);

const _commonSadaqahConditions = [
  {
    'en': 'Sincere intention (ikhlas) — for the sake of Allah alone',
    'fr': 'Intention sincère (ikhlas) — pour Allah seul',
    'es': 'Intención sincera (ikhlas) — solo por Allah',
    'it': 'Intenzione sincera (ikhlas) — per Allah soltanto',
    'de': 'Aufrichtige Absicht (ikhlas) — allein um Allahs willen',
    'pt': 'Intenção sincera (ikhlas) — somente por Allah',
  },
  {
    'en': 'Wealth from a halal source',
    'fr': "Des biens provenant d'une source halal",
    'es': 'Riqueza procedente de una fuente halal',
    'it': 'Beni provenienti da una fonte halal',
    'de': 'Vermögen aus einer halal Quelle',
    'pt': 'Riqueza proveniente de uma fonte halal',
  },
  {
    'en': 'Given without reminder of favour or harm (Quran 2:262)',
    'fr': 'Donné sans rappel du bienfait ni offense (Coran 2:262)',
    'es': 'Dado sin recordar el favor ni causar ofensa (Corán 2:262)',
    'it': 'Donato senza rimproverare il favore né causare offesa (Corano 2:262)',
    'de': 'Gegeben ohne Vorhaltung der Gunst und ohne Kränkung (Koran 2:262)',
    'pt': 'Dado sem lembrar o favor nem causar ofensa (Corão 2:262)',
  },
];

const sadaqahCategories = <DeedCategory>[
  DeedCategory(
    key: 'general',
    labels: {
      'en': 'Sadaqah',
      'fr': 'Sadaqah',
      'es': 'Sadaqah',
      'it': 'Sadaqah',
      'de': 'Sadaqah',
      'pt': 'Sadaqah',
    },
    promises: [_verse2_261, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'jariyah',
    labels: {
      'en': 'Sadaqah Jariyah',
      'fr': 'Sadaqah Jariyah',
      'es': 'Sadaqah Jariyah',
      'it': 'Sadaqah Jariyah',
      'de': 'Sadaqah Jariyah',
      'pt': 'Sadaqah Jariyah',
    },
    promises: [_hadeethJariyah, _verse2_261],
    conditions: [
      ..._commonSadaqahConditions,
      {
        'en': 'A lasting benefit (e.g. a well, a Quran, beneficial knowledge)',
        'fr': 'Un bienfait durable (p. ex. un puits, un Coran, une science bénéfique)',
        'es': 'Un beneficio duradero (p. ej. un pozo, un Corán, un conocimiento beneficioso)',
        'it': 'Un beneficio duraturo (ad es. un pozzo, un Corano, una conoscenza benefica)',
        'de': 'Ein dauerhafter Nutzen (z. B. ein Brunnen, ein Koran, nützliches Wissen)',
        'pt': 'Um benefício duradouro (p. ex. um poço, um Corão, um conhecimento benéfico)',
      },
    ],
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'feeding',
    labels: {
      'en': 'Feeding the Poor',
      'fr': 'Nourrir les pauvres',
      'es': 'Alimentar a los pobres',
      'it': 'Sfamare i poveri',
      'de': 'Die Armen speisen',
      'pt': 'Alimentar os pobres',
    },
    promises: [_verse76_8_9, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
    maxMultiplier: 700,
    maxSource: 'Quran 2:261',
  ),
  DeedCategory(
    key: 'masjid',
    labels: {
      'en': 'Masjid / Orphans',
      'fr': 'Masjid / Orphelins',
      'es': 'Masjid / Huérfanos',
      'it': 'Masjid / Orfani',
      'de': 'Masjid / Waisen',
      'pt': 'Masjid / Órfãos',
    },
    promises: [_hadeethMasjid, _verse6_160],
    conditions: _commonSadaqahConditions,
    minMultiplier: 10,
    minSource: 'Quran 6:160',
  ),
];
