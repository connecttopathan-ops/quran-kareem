import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ═══════════════════════════════════════════════════════════════
// DATA — placeholder structure; full duas to be populated later
// Each dua map keys: title, arabic, transliteration, english,
//   romanUrdu, source, [prophet] (category 1 only)
// ═══════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> duasCategories = [
  {
    'id': 'prophets',
    'name': 'Duas of the Prophets',
    'emoji': '🕌',
    'watermark': 'الأنبياء',
    'hasProphetSections': true,
    'duas': [
      {
        'prophet': 'Prophet Adam (عليه السلام)',
        'title': 'Dua of Repentance',
        'arabic':
            'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        'transliteration':
            'Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal khasireen',
        'english':
            'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
        'romanUrdu':
            'Ae hamare Rabb, hum ne apne aap par zulm kiya aur agar Tu ne hamen maaf na kiya aur hum par raham na kiya to hum yaqeenan nuqsaan uthaane walon mein se honge.',
        'source': 'Quran 7:23',
      },
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': 'Dua for Help Against Disbelievers',
        'arabic': 'رَبِّ إِنِّي مَغْلُوبٌ فَانتَصِرْ',
        'transliteration': 'Rabbi inni maghlubun fantasir',
        'english': 'My Lord, I am overpowered, so help me.',
        'romanUrdu':
            'Ae mere Rabb, main maghlub ho gaya hoon, pas Tu meri madad farma.',
        'source': 'Quran 54:10',
      },
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': 'Dua for Forgiveness',
        'arabic':
            'رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
        'transliteration':
            "Rabbigh-fir li wa liwaalidayya wa liman dakhala baytiya mu'minan wa lil-mu'mineena wal-mu'minaat",
        'english':
            'My Lord, forgive me and my parents and whoever enters my house as a believer and the believing men and believing women.',
        'romanUrdu':
            'Ae mere Rabb, mujhe aur mere walidain ko aur jo bhi mere ghar mein imaan ke saath daakhil ho aur tamaam momin mardon aur momin aurton ko maaf farma.',
        'source': 'Quran 71:28',
      },
    ],
  },
  {
    'id': 'daily',
    'name': 'Daily Duas',
    'emoji': '☀️',
    'watermark': 'اليومية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua When Waking Up',
        'arabic':
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        'transliteration':
            'Alhamdu lillahil-ladhi ahyana ba\'da ma amatana wa ilayhin-nushur',
        'english':
            'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
        'romanUrdu':
            'Tamam taareef Allah ke liye hai jis ne hamen maut dene ke baad zindagi di aur usi ki taraf uthna hai.',
        'source': 'Sahih Bukhari 6312',
      },
      {
        'title': 'Dua Before Eating',
        'arabic': 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        'transliteration': "Bismillahi wa 'ala barakatillah",
        'english': 'In the name of Allah and with the blessings of Allah.',
        'romanUrdu': 'Allah ke naam se aur Allah ki barkat ke saath.',
        'source': 'Sunan Abu Dawud 3767',
      },
    ],
  },
  {
    'id': 'quranic',
    'name': 'Quranic Duas',
    'emoji': '📖',
    'watermark': 'القرآن',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Good in Both Worlds',
        'arabic':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'transliteration':
            "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-naar",
        'english':
            'Our Lord, give us good in this world and good in the Hereafter, and save us from the punishment of the Fire.',
        'romanUrdu':
            'Ae hamare Rabb, hamen dunya mein bhalai de aur aakhirat mein bhalai de aur hamen jahannam ke azaab se bacha.',
        'source': 'Quran 2:201',
      },
      {
        'title': 'Dua for Increase in Knowledge',
        'arabic': 'رَّبِّ زِدْنِي عِلْمًا',
        'transliteration': "Rabbi zidni 'ilma",
        'english': 'My Lord, increase me in knowledge.',
        'romanUrdu': 'Ae mere Rabb, mujhe ilm mein izaafa farma.',
        'source': 'Quran 20:114',
      },
    ],
  },
  {
    'id': 'occasions',
    'name': 'Special Occasions',
    'emoji': '⭐',
    'watermark': 'المناسبات',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Laylatul Qadr',
        'arabic': 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
        'transliteration':
            "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
        'english':
            'O Allah, You are Pardoning and You love pardon, so pardon me.',
        'romanUrdu':
            'Ae Allah, Tu maaf karne wala hai aur maafi ko pasand karta hai, pas mujhe maaf farma de.',
        'source': 'Sunan Ibn Majah 3850',
      },
      {
        'title': 'Dua for Breaking Fast (Iftar)',
        'arabic':
            'اللَّهُمَّ لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
        'transliteration':
            "Allahumma laka sumtu wa bika amantu wa 'alayka tawakkaltu wa 'ala rizqika aftart",
        'english':
            'O Allah, I fasted for You and I believe in You and I put my trust in You and I break my fast with Your sustenance.',
        'romanUrdu':
            'Ae Allah, maine tere liye roza rakha aur tujh par imaan laya aur tujh par bharosa kiya aur tere rizq se iftaar kiya.',
        'source': 'Sunan Abu Dawud 2358',
      },
    ],
  },
  {
    'id': 'protection',
    'name': 'Success & Protection',
    'emoji': '🛡️',
    'watermark': 'الحماية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Protection from Evil Eye',
        'arabic':
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        'transliteration': "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
        'english':
            'I seek refuge in the perfect words of Allah from the evil of what He has created.',
        'romanUrdu':
            'Main Allah ke kaamil kalimat ki panaah maangta hoon us ki tamam makhluq ki burai se.',
        'source': 'Sahih Muslim 2708',
      },
      {
        'title': 'Dua for Debt Relief',
        'arabic':
            'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
        'transliteration':
            "Allahumma-kfini bihalaalika 'an haramika wa aghnini bifadlika 'amman siwak",
        'english':
            'O Allah, suffice me with what You have made lawful so that I have no need of what You have made unlawful, and make me independent of all those other than You by Your grace.',
        'romanUrdu':
            'Ae Allah, apne halaal se mujhe apne haraam se be-niyaaz farma aur apne fazl se mujhe apne siwa sab se be-niyaaz farma.',
        'source': 'Sunan Tirmidhi 3563',
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════
// LEVEL 1 — CATEGORIES PAGE
// ═══════════════════════════════════════════════════════════════

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _searchResults {
    final q = _query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    for (final cat in duasCategories) {
      final catName = cat['name'] as String;
      for (final dua in cat['duas'] as List<dynamic>) {
        final d = dua as Map<String, dynamic>;
        final matchTitle = (d['title'] as String).toLowerCase().contains(q);
        final matchArabic = (d['arabic'] as String).contains(_query);
        final matchEng = (d['english'] as String).toLowerCase().contains(q);
        final matchUrdu =
            (d['romanUrdu'] as String).toLowerCase().contains(q);
        final matchTranslit =
            (d['transliteration'] as String).toLowerCase().contains(q);
        if (matchTitle || matchArabic || matchEng || matchUrdu || matchTranslit) {
          results.add({...d, '_categoryName': catName});
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Duas',
          style: TextStyle(
            color: context.text,
            fontSize: 16,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Bismillah header
                _BismillahHeader(),
                // Search bar
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          if (!searching)
            // Category cards grid
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _CategoryCard(
                    category: duasCategories[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DuasCategoryPage(
                          category: duasCategories[i],
                        ),
                      ),
                    ),
                  ),
                  childCount: duasCategories.length,
                ),
              ),
            )
          else
            // Search results
            _searchResults.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No duas found',
                        style: TextStyle(
                          color: context.textDim,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _SearchResultCard(dua: _searchResults[i]),
                        childCount: _searchResults.length,
                      ),
                    ),
                  ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Bismillah header ──────────────────────────────────────────

class _BismillahHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Scheherazade',
              fontSize: 26,
              color: AppColors.gold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: context.textDim,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ───────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(fontSize: 14, color: context.text),
          decoration: InputDecoration(
            hintText: 'Search duas in any language…',
            hintStyle: TextStyle(fontSize: 13, color: context.textDim),
            prefixIcon:
                Icon(Icons.search, size: 20, color: context.textDim),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 18, color: context.textDim),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duas = category['duas'] as List<dynamic>;
    final count = duas.length;
    final preview1 =
        count > 0 ? (duas[0] as Map<String, dynamic>)['title'] as String : '';
    final preview2 =
        count > 1 ? (duas[1] as Map<String, dynamic>)['title'] as String : '';
    final watermark = category['watermark'] as String;
    final bool dark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [
                    const Color(0xFF1E1A06),
                    const Color(0xFF181408),
                    const Color(0xFF120F04),
                  ]
                : [
                    const Color(0xFFFFFBF0),
                    const Color(0xFFFAF0D0),
                    const Color(0xFFF2E3B0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.gold.withOpacity(dark ? 0.35 : 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(dark ? 0.08 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Arabic watermark
              Positioned(
                right: -10,
                bottom: -12,
                child: Text(
                  watermark,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 72,
                    color: AppColors.gold.withOpacity(dark ? 0.06 : 0.08),
                    height: 1,
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + name row
                    Row(
                      children: [
                        Text(
                          category['emoji'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.text,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.gold.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$count Duas',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.gold.withOpacity(0.7),
                        ),
                      ],
                    ),
                    if (preview1.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: AppColors.gold.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10),
                      // Sneak peek duas
                      _PreviewRow(text: preview1),
                      if (preview2.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _PreviewRow(text: preview2),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String text;
  const _PreviewRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: context.textDim,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Search result card ────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  const _SearchResultCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _ExpandableDuaCard(
        dua: dua,
        categoryLabel: dua['_categoryName'] as String?,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEVEL 2 — DUAS CATEGORY PAGE
// ═══════════════════════════════════════════════════════════════

class DuasCategoryPage extends StatelessWidget {
  final Map<String, dynamic> category;
  const DuasCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final bool hasProphets = category['hasProphetSections'] == true;
    final duas = category['duas'] as List<dynamic>;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category['emoji'] as String,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              category['name'] as String,
              style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: hasProphets
          ? _ProphetGroupedList(duas: duas)
          : _FlatDuaList(duas: duas),
    );
  }
}

// ── Prophet grouped list (Category 1) ────────────────────────

class _ProphetGroupedList extends StatelessWidget {
  final List<dynamic> duas;
  const _ProphetGroupedList({required this.duas});

  Map<String, List<Map<String, dynamic>>> _groupByProphet() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final dua in duas) {
      final d = dua as Map<String, dynamic>;
      final prophet = d['prophet'] as String? ?? 'Other';
      groups.putIfAbsent(prophet, () => []).add(d);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByProphet();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final entry in groups.entries)
          _ProphetSection(
            prophetName: entry.key,
            duas: entry.value,
          ),
      ],
    );
  }
}

// ── Prophet section (collapsible) ────────────────────────────

class _ProphetSection extends StatefulWidget {
  final String prophetName;
  final List<Map<String, dynamic>> duas;
  const _ProphetSection({required this.prophetName, required this.duas});

  @override
  State<_ProphetSection> createState() => _ProphetSectionState();
}

class _ProphetSectionState extends State<_ProphetSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _ctrl;
  late Animation<double> _rotatAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _rotatAnim = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.duas.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prophet header
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.prophetName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.text,
                          ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'Dua' : 'Duas'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotatAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Duas list (animated)
          SizeTransition(
            sizeFactor: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 6),
                for (final dua in widget.duas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExpandableDuaCard(dua: dua),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Flat dua list (Categories 2–5) ───────────────────────────

class _FlatDuaList extends StatelessWidget {
  final List<dynamic> duas;
  const _FlatDuaList({required this.duas});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      itemCount: duas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _ExpandableDuaCard(dua: duas[i] as Map<String, dynamic>),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPANDABLE DUA CARD
// ═══════════════════════════════════════════════════════════════

class _ExpandableDuaCard extends StatefulWidget {
  final Map<String, dynamic> dua;
  final String? categoryLabel;

  const _ExpandableDuaCard({required this.dua, this.categoryLabel});

  @override
  State<_ExpandableDuaCard> createState() => _ExpandableDuaCardState();
}

class _ExpandableDuaCardState extends State<_ExpandableDuaCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _copy(BuildContext context) {
    final d = widget.dua;
    final text =
        '${d['arabic']}\n\n${d['transliteration']}\n\n${d['english']}\n\n${d['romanUrdu']}\n\nSource: ${d['source']}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dua copied to clipboard'),
        backgroundColor: AppColors.goldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    final String title = d['title'] as String;
    final String source = d['source'] as String;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsed header ──────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category label (search results only)
                        if (widget.categoryLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              widget.categoryLabel!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.text,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            source,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.textDim,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 1, color: context.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Arabic text
                      Text(
                        d['arabic'] as String,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Scheherazade',
                          fontSize: 24,
                          color: context.arabic,
                          height: 1.9,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. Transliteration
                      Text(
                        d['transliteration'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: context.translit,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Divider
                      Container(
                        height: 1,
                        color: context.border.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      // 3. English translation
                      _SectionLabel(label: 'English'),
                      const SizedBox(height: 4),
                      Text(
                        d['english'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.text2,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 4. Roman Urdu translation
                      _SectionLabel(label: 'Roman Urdu'),
                      const SizedBox(height: 4),
                      Text(
                        d['romanUrdu'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.urduText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 5. Source + copy button
                      Row(
                        children: [
                          const Icon(Icons.auto_stories_outlined,
                              size: 12, color: AppColors.gold),
                          const SizedBox(width: 5),
                          Text(
                            source,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _copy(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.copy_outlined,
                                      size: 12, color: AppColors.gold),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.gold.withOpacity(0.8),
      ),
    );
  }
}
