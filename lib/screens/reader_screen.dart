import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/surah.dart';
import '../data/quran_data.dart';
import '../services/audio_service.dart';
import '../widgets/q_icons.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  final Surah surah;
  const ReaderScreen({super.key, required this.surah});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<AppState>().keepScreenOn) {
      // Screen wake lock would be applied here when wakelock_plus is added
    }
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AudioService>(),
        child: const _ReaderSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          elevation: 0,
          leading: IconButton(
            icon: QIcon.back(size: 22, color: context.textDim),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(children: [
            Text(widget.surah.nameTransliteration,
                style: TextStyle(color: context.text, fontSize: 16,
                    fontFamily: 'serif', fontWeight: FontWeight.w600)),
            Text(widget.surah.nameEnglish,
                style: TextStyle(color: context.textDim, fontSize: 11,
                    fontFamily: 'sans-serif')),
          ]),
          centerTitle: true,
          actions: [
            IconButton(
              icon: QIcon.bookmark(size: 22, color: context.textDim),
              onPressed: () {},
            ),
            IconButton(
              icon: QIcon.tune(size: 22, color: AppColors.gold),
              onPressed: _openSettings,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: context.border),
          ),
        ),
        body: _buildBody(state),
      );
    });
  }

  Widget _buildBody(AppState state) {
    final verses = kQuranData[widget.surah.number] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      itemCount: verses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _SurahHeader(surah: widget.surah);
        final verse = verses[index - 1];
        return _VerseCard(
          verse: verse,
          surah: widget.surah,
          state: state,
        );
      },
    );
  }
}

// \u2500\u2500 Surah Header \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _SurahHeader extends StatelessWidget {
  final Surah surah;
  const _SurahHeader({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark
              ? [const Color(0xFF1a1508), const Color(0xFF0e0b04)]
              : [const Color(0xFFf5e8cc), const Color(0xFFeddba8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.isDark
            ? const Color(0xFF3a2e10) : AppColors.lightBorder2),
      ),
      child: Column(children: [
        Text(surah.nameArabic,
            style: TextStyle(fontFamily: 'Scheherazade', fontSize: 28,
                color: context.isDark ? AppColors.goldLight : AppColors.goldDark)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _chip(context, surah.type),
          const SizedBox(width: 8),
          _chip(context, '${surah.verses} Aayaat'),
          const SizedBox(width: 8),
          _chip(context, surah.nameEnglish),
        ]),
        if (surah.number != 9) ...[
          const SizedBox(height: 12),
          Text('\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650 \u0627\u0644\u0631\u064e\u0651\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0627\u0644\u0631\u064e\u0651\u062d\u0650\u064a\u0645\u0650',
              style: TextStyle(fontFamily: 'Scheherazade', fontSize: 20,
                  color: AppColors.gold)),
        ],
      ]),
    );
  }

  Widget _chip(BuildContext ctx, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: ctx.isDark ? AppColors.goldDim.withOpacity(0.12) : AppColors.goldFaint.withOpacity(0.5),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: ctx.isDark ? AppColors.goldDim : AppColors.lightBorder2),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, fontFamily: 'sans-serif',
        color: ctx.isDark ? AppColors.goldDim : AppColors.goldDark)),
  );
}

// \u2500\u2500 Verse Card \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _VerseCard extends StatelessWidget {
  final Verse verse;
  final Surah surah;
  final AppState state;
  const _VerseCard({required this.verse, required this.surah, required this.state});

  @override
  Widget build(BuildContext context) {
    final langData = verse.translations[state.langCode] ??
        verse.translations['en'] ??
        const VerseTranslation(transliteration: '', translation: '');

    return Consumer<AudioService>(builder: (context, audio, _) {
      final isThisPlaying = audio.isVersePlayingNow(surah.number, verse.number);
      final isThisLoading = audio.isLoading &&
          audio.nowPlaying?.surahNumber == surah.number &&
          audio.nowPlaying?.verseNumber == verse.number;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isThisPlaying ? AppColors.gold : context.border,
            width: isThisPlaying ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isThisPlaying
                  ? AppColors.goldDim.withOpacity(context.isDark ? 0.15 : 0.1)
                  : context.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: context.border)),
            ),
            child: Row(children: [
              // Verse number badge
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isThisPlaying
                      ? AppColors.gold.withOpacity(0.15)
                      : (context.isDark
                          ? AppColors.goldDim.withOpacity(0.15)
                          : AppColors.goldFaint.withOpacity(0.5)),
                  border: Border.all(
                      color: isThisPlaying ? AppColors.gold : (context.isDark
                          ? AppColors.goldDim : AppColors.lightBorder2)),
                ),
                child: Center(child: Text('${verse.number}',
                    style: TextStyle(fontSize: 9, color: AppColors.gold,
                        fontWeight: FontWeight.bold, fontFamily: 'sans-serif'))),
              ),
              const SizedBox(width: 8),
              Text('${surah.number}:${verse.number}',
                  style: TextStyle(fontSize: 10, letterSpacing: 1,
                      color: context.textDim, fontFamily: 'sans-serif')),

              // Now playing indicator
              if (isThisPlaying) ...[
                const SizedBox(width: 8),
                _NowPlayingDots(),
              ],
              const Spacer(),

              // Play/pause button
              GestureDetector(
                onTap: () {
                  if (isThisPlaying) {
                    audio.togglePlayPause();
                  } else {
                    audio.playVerse(
                      surahNumber: surah.number,
                      surahName: surah.nameTransliteration,
                      verseNumber: verse.number,
                      totalVerses: surah.verses,
                    );
                  }
                },
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isThisPlaying
                        ? AppColors.gold
                        : context.surface,
                    border: Border.all(
                        color: isThisPlaying ? AppColors.gold : context.border),
                  ),
                  child: Center(
                    child: isThisLoading
                        ? SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.white))
                        : isThisPlaying
                            ? QIcon.pause(size: 11, color: Colors.white)
                            : QIcon.play(size: 11, color: context.textDim),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              QIcon.more(size: 16, color: context.textDim),
            ]),
          ),

          // Arabic text
          Container(
            color: context.surface2,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              verse.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: state.arabicFontSize,
                color: context.arabic,
                height: 2.0,
              ),
            ),
          ),

          // Transliteration
          if (state.showTranslit && langData.transliteration.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.border))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ROMAN ARABIC',
                    style: TextStyle(fontSize: 7, letterSpacing: 2,
                        color: AppColors.goldDim, fontFamily: 'sans-serif')),
                const SizedBox(height: 3),
                Text(langData.transliteration,
                    style: TextStyle(fontFamily: 'serif',
                        fontSize: state.translitFontSize,
                        fontStyle: FontStyle.italic,
                        color: context.translit, height: 1.6)),
              ]),
            ),

          // Translation
          if (state.showTranslation && langData.translation.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: context.border)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ROMAN URDU',
                    style: TextStyle(fontSize: 7, letterSpacing: 2,
                        color: AppColors.goldDim, fontFamily: 'sans-serif')),
                const SizedBox(height: 3),
                Text(langData.translation,
                    style: TextStyle(fontFamily: 'serif',
                        fontSize: state.translationFontSize,
                        color: context.urduText, height: 1.6)),
              ]),
            ),
        ]),
      );
    });
  }
}

// Animated "now playing" dots
class _NowPlayingDots extends StatefulWidget {
  @override
  State<_NowPlayingDots> createState() => _NowPlayingDotsState();
}
class _NowPlayingDotsState extends State<_NowPlayingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (t < 0.5 ? 2 * t : 2 * (1 - t));
            return Container(
              width: 4, height: 4 * scale + 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
// READER SETTINGS SHEET
// \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
class _ReaderSettingsSheet extends StatefulWidget {
  const _ReaderSettingsSheet();
  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: context.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
              blurRadius: 30, offset: const Offset(0, -8))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(color: context.border,
                  borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 4),
            child: Row(children: [
              Text('Reader Settings',
                  style: TextStyle(color: context.text, fontSize: 17,
                      fontFamily: 'serif', fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: QIcon.close(size: 20, color: context.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Display', 'Text', 'Audio'].asMap().entries.map((e) {
                final sel = _tabs.index == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _tabs.index = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.goldDim.withOpacity(0.12) : context.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.gold : context.border),
                    ),
                    child: Text(e.value,
                        style: TextStyle(fontSize: 13, fontFamily: 'sans-serif',
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? AppColors.gold : context.textDim)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: [
              _DisplayTab(state: state),
              _TextTab(state: state),
              const _AudioTab(),
            ][_tabs.index],
          ),
        ]),
      );
    });
  }
}

// \u2500\u2500 DISPLAY TAB \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _DisplayTab extends StatelessWidget {
  final AppState state;
  const _DisplayTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SheetLabel('THEME'),
        const SizedBox(height: 8),
        Row(children: [
          _ThemeCard(label: 'Warm', arabic: '\u0628\u0650\u0633\u0652\u0645\u0650',
              bg: const Color(0xFFFFFFFF), textColor: const Color(0xFF2a1e08),
              selected: state.readerTheme == ReaderTheme.warm,
              onTap: () => state.setReaderTheme(ReaderTheme.warm)),
          const SizedBox(width: 8),
          _ThemeCard(label: 'Paper', arabic: '\u0628\u0650\u0633\u0652\u0645\u0650',
              bg: const Color(0xFFFDF3E0), textColor: const Color(0xFF3a2a10),
              selected: state.readerTheme == ReaderTheme.paper,
              onTap: () => state.setReaderTheme(ReaderTheme.paper)),
          const SizedBox(width: 8),
          _ThemeCard(label: 'Dark', arabic: '\u0628\u0650\u0633\u0652\u0645\u0650',
              bg: const Color(0xFF111111), textColor: AppColors.goldLight,
              selected: state.readerTheme == ReaderTheme.dark,
              onTap: () => state.setReaderTheme(ReaderTheme.dark)),
        ]),
        const SizedBox(height: 18),
        _SheetLabel('READING MODE'),
        const SizedBox(height: 8),
        Row(children: [
          _ModeCard(qicon: (c) => QIcon.listMode(size: 22, color: c), label: 'List',
              selected: state.readingMode == ReadingMode.list,
              onTap: () => state.setReadingMode(ReadingMode.list)),
          const SizedBox(width: 8),
          _ModeCard(qicon: (c) => QIcon.pageMode(size: 22, color: c), label: 'Page',
              selected: state.readingMode == ReadingMode.page,
              onTap: () => state.setReadingMode(ReadingMode.page)),
          const SizedBox(width: 8),
          _ModeCard(qicon: (c) => QIcon.focusMode(size: 22, color: c), label: 'Focus',
              selected: state.readingMode == ReadingMode.focus,
              onTap: () => state.setReadingMode(ReadingMode.focus)),
        ]),
        const SizedBox(height: 18),
        _ToggleRow(
          title: 'Keep Screen On', subtitle: 'While reading',
          value: state.keepScreenOn,
          onChanged: (_) {
            state.toggleKeepScreenOn();
          },
        ),
      ]),
    );
  }
}

// \u2500\u2500 TEXT TAB \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _TextTab extends StatelessWidget {
  final AppState state;
  const _TextTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SheetLabel('ARABIC TEXT SIZE'),
        const SizedBox(height: 6),
        _SizeRow(
          preview: Text('\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650',
              style: TextStyle(fontFamily: 'Scheherazade',
                  fontSize: state.arabicFontSize, color: context.arabic),
              textDirection: TextDirection.rtl),
          value: state.arabicFontSize, min: 16, max: 40,
          onMinus: () => state.setArabicFontSize(state.arabicFontSize - 2),
          onPlus:  () => state.setArabicFontSize(state.arabicFontSize + 2),
          onSlide: state.setArabicFontSize,
        ),
        const SizedBox(height: 18),
        _SheetLabel('TRANSLITERATION SIZE'),
        const SizedBox(height: 6),
        _SizeRow(
          preview: Text('Alhamdu lillaahi',
              style: TextStyle(fontFamily: 'serif', fontSize: state.translitFontSize,
                  fontStyle: FontStyle.italic, color: context.translit)),
          value: state.translitFontSize, min: 10, max: 22,
          onMinus: () => state.setTranslitFontSize(state.translitFontSize - 1),
          onPlus:  () => state.setTranslitFontSize(state.translitFontSize + 1),
          onSlide: state.setTranslitFontSize,
        ),
        const SizedBox(height: 18),
        _SheetLabel('TRANSLATION SIZE'),
        const SizedBox(height: 6),
        _SizeRow(
          preview: Text('Tamam taareefein Allah hi ke liye',
              style: TextStyle(fontFamily: 'serif',
                  fontSize: state.translationFontSize, color: context.urduText)),
          value: state.translationFontSize, min: 10, max: 22,
          onMinus: () => state.setTranslationFontSize(state.translationFontSize - 1),
          onPlus:  () => state.setTranslationFontSize(state.translationFontSize + 1),
          onSlide: state.setTranslationFontSize,
        ),
        const SizedBox(height: 18),
        _ToggleRow(title: 'Show Transliteration', subtitle: 'Roman Arabic pronunciation',
            value: state.showTranslit, onChanged: (_) => state.toggleTranslit()),
        const SizedBox(height: 8),
        _ToggleRow(title: 'Show Translation',
            subtitle: 'Meaning in ${state.currentLanguage.name}',
            value: state.showTranslation, onChanged: (_) => state.toggleTranslation()),
      ]),
    );
  }
}

// \u2500\u2500 AUDIO TAB \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _AudioTab extends StatelessWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(builder: (context, audio, _) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16,
            MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Now playing card
          if (audio.nowPlaying != null) ...[
            _SheetLabel('NOW PLAYING'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: context.isDark
                    ? [const Color(0xFF1a1508), const Color(0xFF0e0b04)]
                    : [const Color(0xFFf5e8cc), const Color(0xFFefdba8)]),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: context.isDark
                    ? const Color(0xFF3a2e10) : AppColors.lightBorder2),
              ),
              child: Column(children: [
                Text(audio.nowPlaying!.surahName,
                    style: TextStyle(fontFamily: 'serif', fontSize: 16, color: context.text)),
                Text('Verse ${audio.nowPlaying!.verseNumber} of ${audio.nowPlaying!.totalVerses}',
                    style: TextStyle(fontSize: 11, color: context.textDim,
                        fontFamily: 'sans-serif')),
                const SizedBox(height: 14),
                // Playback controls
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _AudioBtn(
                    icon: QIcon.previousVerse(size: 18, color: context.textDim),
                    onTap: audio.previousVerse,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: audio.togglePlayPause,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: AppColors.gold, shape: BoxShape.circle),
                      child: Center(
                        child: audio.isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : (audio.isPlaying
                                ? QIcon.pause(size: 20, color: Colors.white)
                                : QIcon.play(size: 20, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _AudioBtn(
                    icon: QIcon.nextVerse(size: 18, color: context.textDim),
                    onTap: audio.nextVerse,
                  ),
                ]),
                const SizedBox(height: 10),
                // Stop button
                GestureDetector(
                  onTap: audio.stop,
                  child: Text('Stop', style: TextStyle(
                      fontSize: 11, color: context.textDim,
                      fontFamily: 'sans-serif',
                      decoration: TextDecoration.underline)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
          ],

          // Playback speed
          _SheetLabel('PLAYBACK SPEED'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                final sel = audio.playbackSpeed == speed;
                return GestureDetector(
                  onTap: () => audio.setSpeed(speed),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.goldDim.withOpacity(0.12) : context.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppColors.gold : context.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Text('${speed}x',
                        style: TextStyle(fontSize: 13, fontFamily: 'sans-serif',
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                            color: sel ? AppColors.gold : context.textDim)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Reciter selector
          _SheetLabel('RECITER'),
          const SizedBox(height: 8),
          ...Reciter.all.map((r) {
            final sel = audio.reciterId == r.id;
            return GestureDetector(
              onTap: () => audio.setReciter(r.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.goldDim.withOpacity(0.1) : context.surface2,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: sel ? AppColors.gold : context.border,
                      width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: TextStyle(fontSize: 13,
                        color: sel ? AppColors.gold : context.text,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                    Row(children: [
                      Text(r.arabicName,
                          style: TextStyle(fontFamily: 'Scheherazade', fontSize: 13,
                              color: context.isDark ? AppColors.goldDim : AppColors.goldDark)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(r.style, style: TextStyle(fontSize: 8,
                            fontFamily: 'sans-serif', color: context.textDim)),
                      ),
                    ]),
                  ])),
                  if (sel) QIcon.check(size: 16, color: AppColors.gold),
                ]),
              ),
            );
          }),
        ]),
      );
    });
  }
}

class _AudioBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _AudioBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: context.surface2,
            border: Border.all(color: context.border)),
        child: Center(child: icon),
      ),
    );
  }
}

// \u2500\u2500 SHARED WIDGETS \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: TextStyle(fontSize: 9, letterSpacing: 2.5,
          color: ctx.textDim, fontFamily: 'sans-serif', fontWeight: FontWeight.w600));
}

class _ThemeCard extends StatelessWidget {
  final String label, arabic;
  final Color bg, textColor;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard({required this.label, required this.arabic, required this.bg,
      required this.textColor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.gold : context.border,
                width: selected ? 1.5 : 1)),
        child: Column(children: [
          Text(arabic, style: TextStyle(fontFamily: 'Scheherazade',
              fontSize: 18, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontFamily: 'sans-serif',
              color: selected ? AppColors.gold : context.textDim,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  final Widget Function(Color) qicon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.qicon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppColors.gold : context.textDim;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldDim.withOpacity(0.08) : context.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.gold : context.border,
                width: selected ? 1.5 : 1),
          ),
          child: Column(children: [
            qicon(c),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 11, fontFamily: 'sans-serif',
                color: c, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final Widget preview;
  final double value, min, max;
  final VoidCallback onMinus, onPlus;
  final ValueChanged<double> onSlide;
  const _SizeRow({required this.preview, required this.value, required this.min,
      required this.max, required this.onMinus, required this.onPlus, required this.onSlide});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _CircleBtn(qicon: (c) => QIcon.minus(size: 16, color: c), onTap: onMinus),
        Expanded(child: Container(height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center, child: preview)),
        _CircleBtn(qicon: (c) => QIcon.plus(size: 16, color: c), onTap: onPlus),
      ]),
      const SizedBox(height: 10),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.gold,
          inactiveTrackColor: context.border,
          thumbColor: AppColors.gold,
          overlayColor: AppColors.gold.withOpacity(0.1),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onSlide),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('A', style: TextStyle(fontSize: 11, color: context.textDim, fontFamily: 'sans-serif')),
          Text('A', style: TextStyle(fontSize: 17, color: context.textDim, fontFamily: 'sans-serif')),
        ]),
      ),
    ]);
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget Function(Color) qicon;
  final VoidCallback onTap;
  const _CircleBtn({required this.qicon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(shape: BoxShape.circle,
          color: context.surface2, border: Border.all(color: context.border)),
      child: Center(child: qicon(AppColors.goldDim)),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.title, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: context.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.text2, fontSize: 13)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: context.textDim, fontSize: 10,
            fontFamily: 'sans-serif')),
      ])),
      Switch(value: value, onChanged: onChanged,
          activeColor: AppColors.gold, activeTrackColor: AppColors.goldDim.withOpacity(0.4)),
    ]),
  );
}