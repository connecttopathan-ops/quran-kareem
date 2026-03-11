import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

const List<Map<String, dynamic>> duasData = [
  {
    'category': 'Morning & Evening',
    'duas': [
      {
        'title': 'Morning Remembrance',
        'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
        'transliteration': 'Asbahna wa asbahal mulku lillah',
        'translation': 'We have entered the morning and the whole kingdom belongs to Allah.',
        'reference': 'Abu Dawud 5077',
      },
      {
        'title': 'Evening Remembrance',
        'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
        'transliteration': 'Amsayna wa amsal mulku lillah',
        'translation': 'We have entered the evening and the whole kingdom belongs to Allah.',
        'reference': 'Abu Dawud 5078',
      },
    ],
  },
  {
    'category': 'Before & After Eating',
    'duas': [
      {
        'title': 'Before Eating',
        'arabic': 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        'transliteration': 'Bismillahi wa ala barakatillah',
        'translation': 'In the name of Allah and with the blessings of Allah.',
        'reference': 'Abu Dawud 3767',
      },
      {
        'title': 'After Eating',
        'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا',
        'transliteration': 'Alhamdulillahil-lazi at-amana',
        'translation': 'All praise is to Allah who fed us.',
        'reference': 'Tirmidhi 3457',
      },
    ],
  },
  {
    'category': 'Travel & Home',
    'duas': [
      {
        'title': 'Leaving the House',
        'arabic': 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ',
        'transliteration': 'Bismillahi tawakkaltu alallah',
        'translation': 'In the name of Allah, I place my trust in Allah.',
        'reference': 'Abu Dawud 5095',
      },
      {
        'title': 'Entering the House',
        'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلَجِ',
        'transliteration': "Allahumma inni as'aluka khayral mawlaj",
        'translation': 'O Allah, I ask You for the good of entering.',
        'reference': 'Abu Dawud 5096',
      },
    ],
  },
  {
    'category': 'Sleep & Waking',
    'duas': [
      {
        'title': 'Before Sleeping',
        'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        'transliteration': 'Bismika allahumma amutu wa ahya',
        'translation': 'In Your name, O Allah, I die and I live.',
        'reference': 'Bukhari 6312',
      },
      {
        'title': 'Upon Waking',
        'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا',
        'transliteration': 'Alhamdulillahil-lazi ahyana badama amatana',
        'translation': 'Praise be to Allah who gave us life after causing us to die.',
        'reference': 'Bukhari 6312',
      },
    ],
  },
  {
    'category': 'Forgiveness & Protection',
    'duas': [
      {
        'title': 'Seeking Forgiveness',
        'arabic': 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ',
        'transliteration': 'Rabbighfir li wa tub alayya',
        'translation': 'My Lord, forgive me and accept my repentance.',
        'reference': 'Bukhari 6307',
      },
      {
        'title': 'Protection from Evil',
        'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
        'transliteration': "A'udhu bikalimatillahit-tammati",
        'translation': 'I seek refuge in the perfect words of Allah.',
        'reference': 'Muslim 2708',
      },
    ],
  },
];

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Duas',
            style: TextStyle(
                color: context.text,
                fontSize: 16,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          for (final category in duasData) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                (category['category'] as String).toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'sans-serif'),
              ),
            ),
            for (final dua in category['duas'] as List<dynamic>)
              _DuaCard(dua: dua as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  const _DuaCard({required this.dua});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(
        text: '${dua['arabic']}\n\n${dua['translation']}'));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(dua['title'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.text)),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                color: context.textDim,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          // Arabic
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                dua['arabic'] as String,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 20,
                    color: AppColors.gold,
                    height: 1.8),
              ),
            ),
          ),
          // Transliteration
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              dua['transliteration'] as String,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: context.textDim),
            ),
          ),
          // Translation
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              dua['translation'] as String,
              style: TextStyle(fontSize: 13, color: context.text2),
            ),
          ),
          // Reference
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.textDim.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dua['reference'] as String,
                style:
                    TextStyle(fontSize: 10, color: context.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
