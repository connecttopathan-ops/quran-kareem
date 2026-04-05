import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';
import 'hifz_loop_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HIFZ SCREEN  —  Surah browser showing memorization progress
// ─────────────────────────────────────────────────────────────────────────────

enum _HifzSort { surahOrder, progress, fewestVerses }

class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});

  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  /// memorized[surahNumber] = set of memorized verse numbers (1-based)
  Map<int, Set<int>> _memorized = {};
  int _totalMemorized = 0;
  int _surahsMemorized = 0;
  int _todayReps = 0;
  _HifzSort _sort = _HifzSort.surahOrder;
  bool _loading = true;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const int _totalAyahs = 6236;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, Set<int>> mem = {};
    int total = 0;

    int surahsDone = 0;
    for (final surah in kSurahs) {
      final set = <int>{};
      for (int v = 1; v <= surah.verses; v++) {
        if (prefs.getBool('hifz_ayah_${surah.number}_$v') == true) {
          set.add(v);
          total++;
        }
      }
      if (set.length == surah.verses) surahsDone++;
      mem[surah.number] = set;
    }

    final today = _todayKey();
    final reps = prefs.getInt('hifz_reps_$today') ?? 0;

    if (mounted) {
      setState(() {
        _memorized = mem;
        _totalMemorized = total;
        _surahsMemorized = surahsDone;
        _todayReps = reps;
        _loading = false;
      });
    }
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<dynamic> _sortedSurahs() {
    var list = List.of(kSurahs);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((s) {
        final q = _searchQuery;
        return s.nameTransliteration.toLowerCase().contains(q) ||
            s.nameArabic.contains(q) ||
            s.number.toString() == q;
      }).toList();
      return list; // skip sort when searching — relevance order
    }

    switch (_sort) {
      case _HifzSort.surahOrder:
        break; // already in order
      case _HifzSort.progress:
        list.sort((a, b) {
          final pa = (_memorized[a.number]?.length ?? 0) / a.verses;
          final pb = (_memorized[b.number]?.length ?? 0) / b.verses;
          return pb.compareTo(pa);
        });
        break;
      case _HifzSort.fewestVerses:
        list.sort((a, b) => a.verses.compareTo(b.verses));
        break;
    }
    return list;
  }

  void _openHifz(int surahNumber) async {
    final surah = kSurahs[surahNumber - 1];
    // Find first un-memorized verse, or start from 1
    final mem = _memorized[surahNumber] ?? {};
    int startVerse = 1;
    for (int v = 1; v <= surah.verses; v++) {
      if (!mem.contains(v)) {
        startVerse = v;
        break;
      }
    }
    final langCode = context.read<AppState>().langCode;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HifzLoopScreen(
          surahNumber: surahNumber,
          initialVerse: startVerse,
          langCode: langCode,
          onMemorizationChanged: _loadData,
        ),
      ),
    );
    _loadData();
  }

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
        title: Text(
          'Hifz',
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
          child: Divider(height: 1, color: context.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final pct = _totalMemorized / _totalAyahs;
    final visibleSurahs = _sortedSurahs();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildMetrics(pct)),
        SliverToBoxAdapter(child: _buildSearchBar()),
        if (_searchQuery.isEmpty)
          SliverToBoxAdapter(child: _buildSortChips()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _SurahProgressTile(
              surah: visibleSurahs[i],
              memorizedCount:
                  _memorized[visibleSurahs[i].number]?.length ?? 0,
              onTap: () => _openHifz(visibleSurahs[i].number),
            ),
            childCount: visibleSurahs.length,
          ),
        ),
        if (visibleSurahs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No surahs found',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textDim, fontSize: 14),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(color: context.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search surah name or number…',
            hintStyle: TextStyle(color: context.textDim, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: context.textDim, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: context.textDim, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(double pct) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.menu_book_rounded,
                  value: _surahsMemorized.toString(),
                  label: 'Surahs',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.star_rounded,
                  value: _totalMemorized.toString(),
                  label: 'Ayahs',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.repeat_rounded,
                  value: _todayReps.toString(),
                  label: "Today's Reps",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quran Progress',
                      style: TextStyle(
                        color: context.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: context.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_totalMemorized of $_totalAyahs ayahs',
                  style: TextStyle(
                    color: context.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style:
                TextStyle(color: context.textDim, fontSize: 12),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Surah',
            selected: _sort == _HifzSort.surahOrder,
            onTap: () => setState(() => _sort = _HifzSort.surahOrder),
          ),
          const SizedBox(width: 6),
          _SortChip(
            label: 'Progress',
            selected: _sort == _HifzSort.progress,
            onTap: () => setState(() => _sort = _HifzSort.progress),
          ),
          const SizedBox(width: 6),
          _SortChip(
            label: 'Shortest',
            selected: _sort == _HifzSort.fewestVerses,
            onTap: () => setState(() => _sort = _HifzSort.fewestVerses),
          ),
        ],
      ),
    );
  }
}

// ── Metric card ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MetricCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: context.textDim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort chip ────────────────────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.textDim,
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Surah progress tile ──────────────────────────────────────────────────────
class _SurahProgressTile extends StatelessWidget {
  final dynamic surah;
  final int memorizedCount;
  final VoidCallback onTap;

  const _SurahProgressTile({
    required this.surah,
    required this.memorizedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = memorizedCount / surah.verses;
    final isComplete = memorizedCount == surah.verses;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isComplete
                ? AppColors.gold.withOpacity(0.5)
                : context.border,
          ),
        ),
        child: Row(
          children: [
            // Surah number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.gold.withOpacity(0.15)
                    : context.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  surah.number.toString(),
                  style: TextStyle(
                    color:
                        isComplete ? AppColors.gold : context.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Names + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          surah.nameTransliteration,
                          style: TextStyle(
                            color: context.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        surah.nameArabic,
                        style: const TextStyle(
                          fontFamily: 'Scheherazade',
                          fontSize: 15,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppColors.gold : AppColors.gold.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$memorizedCount / ${surah.verses} verses',
                    style: TextStyle(
                      color: context.textDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isComplete ? AppColors.gold : context.textDim,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
