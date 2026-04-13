import 'package:flutter/material.dart';

class AsmaEntry {
  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;

  const AsmaEntry({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });
}

/// 15-colour warm palette — cycled across all 99 names.
const List<Color> kAsmaColors = [
  Color(0xFFC17A2B), // amber
  Color(0xFFB05A38), // terracotta
  Color(0xFF4A7C6A), // sage teal
  Color(0xFF3A6E9A), // slate blue
  Color(0xFF8A3A5C), // burgundy
  Color(0xFF3A7A50), // forest green
  Color(0xFF6A4A8A), // indigo
  Color(0xFF8A6040), // warm brown
  Color(0xFF3A7E78), // seafoam
  Color(0xFFA04A2A), // rust
  Color(0xFF7A3A4E), // wine
  Color(0xFF4A6A8A), // steel blue
  Color(0xFF6A7A30), // olive
  Color(0xFF7A4A6A), // mauve
  Color(0xFF4A8060), // moss green
];

/// Returns the display colour for a given name [number] (1–99).
Color asmaColor(int number) => kAsmaColors[(number - 1) % kAsmaColors.length];

const List<AsmaEntry> kAsmaUlHusna = [
  AsmaEntry(number:  1, arabic: 'الرَّحْمَٰنُ',               transliteration: 'Ar-Rahman',          meaning: 'The Most Gracious'),
  AsmaEntry(number:  2, arabic: 'الرَّحِيمُ',                 transliteration: 'Ar-Raheem',           meaning: 'The Most Merciful'),
  AsmaEntry(number:  3, arabic: 'الْمَلِكُ',                  transliteration: 'Al-Malik',            meaning: 'The King'),
  AsmaEntry(number:  4, arabic: 'الْقُدُّوسُ',                transliteration: 'Al-Quddus',           meaning: 'The Most Holy'),
  AsmaEntry(number:  5, arabic: 'السَّلَامُ',                 transliteration: 'As-Salam',            meaning: 'The Source of Peace'),
  AsmaEntry(number:  6, arabic: 'الْمُؤْمِنُ',                transliteration: "Al-Mu'min",           meaning: 'The Guardian of Faith'),
  AsmaEntry(number:  7, arabic: 'الْمُهَيْمِنُ',              transliteration: 'Al-Muhaymin',         meaning: 'The Protector'),
  AsmaEntry(number:  8, arabic: 'الْعَزِيزُ',                 transliteration: 'Al-Aziz',             meaning: 'The Almighty'),
  AsmaEntry(number:  9, arabic: 'الْجَبَّارُ',                transliteration: 'Al-Jabbar',           meaning: 'The Compeller'),
  AsmaEntry(number: 10, arabic: 'الْمُتَكَبِّرُ',             transliteration: 'Al-Mutakabbir',       meaning: 'The Majestic'),
  AsmaEntry(number: 11, arabic: 'الْخَالِقُ',                 transliteration: 'Al-Khaliq',           meaning: 'The Creator'),
  AsmaEntry(number: 12, arabic: 'الْبَارِئُ',                 transliteration: "Al-Bari'",            meaning: 'The Originator'),
  AsmaEntry(number: 13, arabic: 'الْمُصَوِّرُ',               transliteration: 'Al-Musawwir',         meaning: 'The Fashioner'),
  AsmaEntry(number: 14, arabic: 'الْغَفَّارُ',                transliteration: 'Al-Ghaffar',          meaning: 'The Repeatedly Forgiving'),
  AsmaEntry(number: 15, arabic: 'الْقَهَّارُ',                transliteration: 'Al-Qahhar',           meaning: 'The Subduer'),
  AsmaEntry(number: 16, arabic: 'الْوَهَّابُ',                transliteration: 'Al-Wahhab',           meaning: 'The Bestower'),
  AsmaEntry(number: 17, arabic: 'الرَّزَّاقُ',                transliteration: 'Ar-Razzaq',           meaning: 'The Provider'),
  AsmaEntry(number: 18, arabic: 'الْفَتَّاحُ',                transliteration: 'Al-Fattah',           meaning: 'The Opener'),
  AsmaEntry(number: 19, arabic: 'الْعَلِيمُ',                 transliteration: "Al-'Alim",            meaning: 'The All-Knowing'),
  AsmaEntry(number: 20, arabic: 'الْقَابِضُ',                 transliteration: 'Al-Qabid',            meaning: 'The Withholder'),
  AsmaEntry(number: 21, arabic: 'الْبَاسِطُ',                 transliteration: 'Al-Basit',            meaning: 'The Extender'),
  AsmaEntry(number: 22, arabic: 'الْخَافِضُ',                 transliteration: 'Al-Khafid',           meaning: 'The Abaser'),
  AsmaEntry(number: 23, arabic: 'الرَّافِعُ',                 transliteration: "Ar-Rafi'",            meaning: 'The Exalter'),
  AsmaEntry(number: 24, arabic: 'الْمُعِزُّ',                 transliteration: "Al-Mu'izz",           meaning: 'The Honourer'),
  AsmaEntry(number: 25, arabic: 'الْمُذِلُّ',                 transliteration: 'Al-Mudhill',          meaning: 'The Humiliator'),
  AsmaEntry(number: 26, arabic: 'السَّمِيعُ',                 transliteration: "As-Sami'",            meaning: 'The All-Hearing'),
  AsmaEntry(number: 27, arabic: 'الْبَصِيرُ',                 transliteration: 'Al-Basir',            meaning: 'The All-Seeing'),
  AsmaEntry(number: 28, arabic: 'الْحَكَمُ',                  transliteration: 'Al-Hakam',            meaning: 'The Judge'),
  AsmaEntry(number: 29, arabic: 'الْعَدْلُ',                  transliteration: 'Al-Adl',              meaning: 'The Just'),
  AsmaEntry(number: 30, arabic: 'اللَّطِيفُ',                 transliteration: 'Al-Latif',            meaning: 'The Subtle One'),
  AsmaEntry(number: 31, arabic: 'الْخَبِيرُ',                 transliteration: 'Al-Khabir',           meaning: 'The All-Aware'),
  AsmaEntry(number: 32, arabic: 'الْحَلِيمُ',                 transliteration: 'Al-Halim',            meaning: 'The Forbearing'),
  AsmaEntry(number: 33, arabic: 'الْعَظِيمُ',                 transliteration: "Al-'Azim",            meaning: 'The Magnificent'),
  AsmaEntry(number: 34, arabic: 'الْغَفُورُ',                 transliteration: 'Al-Ghafur',           meaning: 'The Forgiving'),
  AsmaEntry(number: 35, arabic: 'الشَّكُورُ',                 transliteration: 'Ash-Shakur',          meaning: 'The Appreciative'),
  AsmaEntry(number: 36, arabic: 'الْعَلِيُّ',                 transliteration: "Al-'Ali",             meaning: 'The Most High'),
  AsmaEntry(number: 37, arabic: 'الْكَبِيرُ',                 transliteration: 'Al-Kabir',            meaning: 'The Greatest'),
  AsmaEntry(number: 38, arabic: 'الْحَفِيظُ',                 transliteration: 'Al-Hafiz',            meaning: 'The Preserver'),
  AsmaEntry(number: 39, arabic: 'الْمُقِيتُ',                 transliteration: 'Al-Muqit',            meaning: 'The Sustainer'),
  AsmaEntry(number: 40, arabic: 'الْحَسِيبُ',                 transliteration: 'Al-Hasib',            meaning: 'The Reckoner'),
  AsmaEntry(number: 41, arabic: 'الْجَلِيلُ',                 transliteration: 'Al-Jalil',            meaning: 'The Majestic'),
  AsmaEntry(number: 42, arabic: 'الْكَرِيمُ',                 transliteration: 'Al-Karim',            meaning: 'The Generous'),
  AsmaEntry(number: 43, arabic: 'الرَّقِيبُ',                 transliteration: 'Ar-Raqib',            meaning: 'The Watchful'),
  AsmaEntry(number: 44, arabic: 'الْمُجِيبُ',                 transliteration: 'Al-Mujib',            meaning: 'The Responsive'),
  AsmaEntry(number: 45, arabic: "الْوَاسِعُ",                 transliteration: "Al-Wasi'",            meaning: 'The All-Encompassing'),
  AsmaEntry(number: 46, arabic: 'الْحَكِيمُ',                 transliteration: 'Al-Hakim',            meaning: 'The Wise'),
  AsmaEntry(number: 47, arabic: 'الْوَدُودُ',                 transliteration: 'Al-Wadud',            meaning: 'The Loving'),
  AsmaEntry(number: 48, arabic: 'الْمَجِيدُ',                 transliteration: 'Al-Majid',            meaning: 'The Most Glorious'),
  AsmaEntry(number: 49, arabic: 'الْبَاعِثُ',                 transliteration: "Al-Ba'ith",           meaning: 'The Resurrector'),
  AsmaEntry(number: 50, arabic: 'الشَّهِيدُ',                 transliteration: 'Ash-Shahid',          meaning: 'The Witness'),
  AsmaEntry(number: 51, arabic: 'الْحَقُّ',                   transliteration: 'Al-Haqq',             meaning: 'The Truth'),
  AsmaEntry(number: 52, arabic: 'الْوَكِيلُ',                 transliteration: 'Al-Wakil',            meaning: 'The Trustee'),
  AsmaEntry(number: 53, arabic: 'الْقَوِيُّ',                 transliteration: 'Al-Qawi',             meaning: 'The Most Strong'),
  AsmaEntry(number: 54, arabic: 'الْمَتِينُ',                 transliteration: 'Al-Matin',            meaning: 'The Firm'),
  AsmaEntry(number: 55, arabic: 'الْوَلِيُّ',                 transliteration: "Al-Wali",             meaning: 'The Protecting Friend'),
  AsmaEntry(number: 56, arabic: 'الْحَمِيدُ',                 transliteration: 'Al-Hamid',            meaning: 'The Praiseworthy'),
  AsmaEntry(number: 57, arabic: 'الْمُحْصِيُ',                transliteration: 'Al-Muhsi',            meaning: 'The Counter'),
  AsmaEntry(number: 58, arabic: 'الْمُبْدِئُ',                transliteration: "Al-Mubdi'",           meaning: 'The Originator'),
  AsmaEntry(number: 59, arabic: 'الْمُعِيدُ',                 transliteration: "Al-Mu'id",            meaning: 'The Restorer'),
  AsmaEntry(number: 60, arabic: 'الْمُحْيِي',                 transliteration: 'Al-Muhyi',            meaning: 'The Giver of Life'),
  AsmaEntry(number: 61, arabic: 'الْمُمِيتُ',                 transliteration: 'Al-Mumit',            meaning: 'The Taker of Life'),
  AsmaEntry(number: 62, arabic: 'الْحَيُّ',                   transliteration: 'Al-Hayy',             meaning: 'The Ever Living'),
  AsmaEntry(number: 63, arabic: 'الْقَيُّومُ',                transliteration: 'Al-Qayyum',           meaning: 'The Self-Subsisting'),
  AsmaEntry(number: 64, arabic: 'الْوَاجِدُ',                 transliteration: 'Al-Wajid',            meaning: 'The Finder'),
  AsmaEntry(number: 65, arabic: 'الْمَاجِدُ',                 transliteration: 'Al-Majid',            meaning: 'The Noble'),
  AsmaEntry(number: 66, arabic: 'الْوَاحِدُ',                 transliteration: 'Al-Wahid',            meaning: 'The One'),
  AsmaEntry(number: 67, arabic: 'الْأَحَدُ',                  transliteration: 'Al-Ahad',             meaning: 'The Unique'),
  AsmaEntry(number: 68, arabic: 'الصَّمَدُ',                  transliteration: 'As-Samad',            meaning: 'The Eternal'),
  AsmaEntry(number: 69, arabic: 'الْقَادِرُ',                 transliteration: 'Al-Qadir',            meaning: 'The Capable'),
  AsmaEntry(number: 70, arabic: 'الْمُقْتَدِرُ',              transliteration: 'Al-Muqtadir',         meaning: 'The Powerful'),
  AsmaEntry(number: 71, arabic: 'الْمُقَدِّمُ',               transliteration: 'Al-Muqaddim',         meaning: 'The Expediter'),
  AsmaEntry(number: 72, arabic: 'الْمُؤَخِّرُ',               transliteration: "Al-Mu'akhkhir",       meaning: 'The Delayer'),
  AsmaEntry(number: 73, arabic: 'الْأَوَّلُ',                 transliteration: 'Al-Awwal',            meaning: 'The First'),
  AsmaEntry(number: 74, arabic: 'الْآخِرُ',                   transliteration: 'Al-Akhir',            meaning: 'The Last'),
  AsmaEntry(number: 75, arabic: 'الظَّاهِرُ',                 transliteration: 'Az-Zahir',            meaning: 'The Manifest'),
  AsmaEntry(number: 76, arabic: 'الْبَاطِنُ',                 transliteration: 'Al-Batin',            meaning: 'The Hidden'),
  AsmaEntry(number: 77, arabic: 'الْوَالِي',                  transliteration: 'Al-Wali',             meaning: 'The Governor'),
  AsmaEntry(number: 78, arabic: 'الْمُتَعَالِي',              transliteration: "Al-Muta'ali",         meaning: 'The Most Exalted'),
  AsmaEntry(number: 79, arabic: 'الْبَرُّ',                   transliteration: 'Al-Barr',             meaning: 'The Source of Goodness'),
  AsmaEntry(number: 80, arabic: 'التَّوَّابُ',                transliteration: 'At-Tawwab',           meaning: 'The Acceptor of Repentance'),
  AsmaEntry(number: 81, arabic: 'الْمُنْتَقِمُ',              transliteration: 'Al-Muntaqim',         meaning: 'The Avenger'),
  AsmaEntry(number: 82, arabic: 'الْعَفُوُّ',                 transliteration: "Al-'Afuw",            meaning: 'The Pardoner'),
  AsmaEntry(number: 83, arabic: 'الرَّؤُوفُ',                 transliteration: "Ar-Ra'uf",            meaning: 'The Compassionate'),
  AsmaEntry(number: 84, arabic: 'مَالِكُ الْمُلْكِ',          transliteration: 'Malik-ul-Mulk',       meaning: 'Owner of Sovereignty'),
  AsmaEntry(number: 85, arabic: 'ذُو الْجَلَالِ وَالْإِكْرَامِ', transliteration: 'Dhul-Jalali wal-Ikram', meaning: 'Lord of Majesty and Bounty'),
  AsmaEntry(number: 86, arabic: 'الْمُقْسِطُ',                transliteration: 'Al-Muqsit',           meaning: 'The Equitable'),
  AsmaEntry(number: 87, arabic: 'الْجَامِعُ',                 transliteration: "Al-Jami'",            meaning: 'The Gatherer'),
  AsmaEntry(number: 88, arabic: 'الْغَنِيُّ',                 transliteration: 'Al-Ghani',            meaning: 'The Self-Sufficient'),
  AsmaEntry(number: 89, arabic: 'الْمُغْنِي',                 transliteration: 'Al-Mughni',           meaning: 'The Enricher'),
  AsmaEntry(number: 90, arabic: 'الْمَانِعُ',                 transliteration: "Al-Mani'",            meaning: 'The Preventer'),
  AsmaEntry(number: 91, arabic: 'الضَّارُّ',                  transliteration: 'Ad-Darr',             meaning: 'The Distressor'),
  AsmaEntry(number: 92, arabic: 'النَّافِعُ',                 transliteration: "An-Nafi'",            meaning: 'The Propitious'),
  AsmaEntry(number: 93, arabic: 'النُّورُ',                   transliteration: 'An-Nur',              meaning: 'The Light'),
  AsmaEntry(number: 94, arabic: 'الْهَادِي',                  transliteration: 'Al-Hadi',             meaning: 'The Guide'),
  AsmaEntry(number: 95, arabic: 'الْبَدِيعُ',                 transliteration: "Al-Badi'",            meaning: 'The Incomparable'),
  AsmaEntry(number: 96, arabic: 'الْبَاقِي',                  transliteration: 'Al-Baqi',             meaning: 'The Everlasting'),
  AsmaEntry(number: 97, arabic: 'الْوَارِثُ',                 transliteration: 'Al-Warith',           meaning: 'The Inheritor'),
  AsmaEntry(number: 98, arabic: 'الرَّشِيدُ',                 transliteration: 'Ar-Rashid',           meaning: 'The Guide to the Right Path'),
  AsmaEntry(number: 99, arabic: 'الصَّبُورُ',                 transliteration: 'As-Sabur',            meaning: 'The Patient'),
];
