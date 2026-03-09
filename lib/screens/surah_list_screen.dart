import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../data/quran_data.dart';
import '../widgets/q_icons.dart';
import 'reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kSurahs
        .where((s) =>
            s.nameTransliteration
                .toLowerCase()
                .contains(_query.toLowerCase()) ||
            s.nameTranslation
                .toLowerCase()
                .contains(_query.toLowerCase()) ||
            s.number.toString().contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('القُرآنُ الكَرِيم',
                          style: TextStyle(
                              fontFamily: 'Scheherazade',
                              fontSize: 22,
                              color: context.isDark
                                  ? AppColors.gold
                                  : AppColors.goldDark)),
                      const Spacer(),
                      Text('114 Surahs',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textDim,
                              fontFamily: 'sans-serif')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ctrl,
                    style: TextStyle(color: context.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search surah...',
                      hintStyle:
                          TextStyle(color: context.textDim, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(11),
                        child: QIcon.search(size: 17, color: context.textDim),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: QIcon.close(size: 16, color: context.textDim),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.gold),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  return _SurahTile(surah: s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final surah;
  const _SurahTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReaderScreen(surah: surah)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.goldDim.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: context.border),
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    color: context.isDark ? AppColors.gold : AppColors.goldDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.nameTransliteration,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.text)),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.verses} verses · ${surah.revelationType} · Juz ${surah.juz}',
                    style: TextStyle(
                        fontSize: 10,
                        color: context.textDim,
                        fontFamily: 'sans-serif'),
                  ),
                ],
              ),
            ),
            // Arabic name
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(surah.nameArabic,
                    style: TextStyle(
                        fontFamily: 'Scheherazade',
                        fontSize: 18,
                        color: context.isDark
                            ? AppColors.gold
                            : AppColors.goldDark)),
                const SizedBox(height: 2),
                Text(surah.nameTranslation,
                    style: TextStyle(
                        fontSize: 9,
                        color: context.textDim,
                        fontFamily: 'sans-serif')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
