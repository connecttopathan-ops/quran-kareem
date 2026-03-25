import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/islamic_book.dart';
import '../services/book_download_service.dart';

class BookReaderScreen extends StatefulWidget {
  final IslamicBook book;
  final int chapterNumber;
  final String chapterTitle;
  final int totalChapters;

  const BookReaderScreen({
    super.key,
    required this.book,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.totalChapters,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  List<Map<String, dynamic>> _hadiths = [];
  bool _loading = true;
  int _currentChapter = 0;
  int _currentHadithIndex = 0;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapterNumber;
    _loadChapter(_currentChapter);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Save position as we scroll
    _saveCurrentPosition();
  }

  Future<void> _loadChapter(int chapterNum) async {
    setState(() => _loading = true);
    final svc = context.read<BookDownloadService>();
    List<Map<String, dynamic>> entries;

    if (widget.book.category == BookCategory.hadith) {
      entries = await svc.loadHadiths(widget.book, chapterNum);
      if (entries.isEmpty) {
        entries = _stubHadiths(chapterNum);
      }
    } else {
      // Seerah: load chapter text from bundled JSON asset
      entries = await svc.loadSeerahChapter(widget.book, chapterNum);
      if (entries.isEmpty) {
        entries = _stubSeerahChapter(chapterNum);
      }
    }

    if (mounted) {
      setState(() {
        _hadiths = entries;
        _loading = false;
        _currentHadithIndex = 0;
      });
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      await _saveCurrentPosition();
    }
  }

  Future<void> _saveCurrentPosition() async {
    final svc = context.read<BookDownloadService>();
    final position =
        '$_currentChapter:$_currentHadithIndex';
    await svc.savePosition(widget.book.id, position);
    final progress = _currentChapter / widget.totalChapters;
    await svc.saveReadingProgress(widget.book.id, progress);
  }

  // Stub data shown when API content isn't available
  List<Map<String, dynamic>> _stubHadiths(int bookNum) {
    return List.generate(
      5,
      (i) => {
        'hadithNumber': '$bookNum:${i + 1}',
        'hadith': [
          {
            'lang': 'en',
            'narrator':
                'Narrated by Abu Hurairah (رضي الله عنه)',
            'body':
                'Download content is not yet available. Please ensure you have downloaded '
                    'the book and have a valid API key configured for sunnah.com.',
          }
        ],
      },
    );
  }

  List<Map<String, dynamic>> _stubSeerahChapter(int chapterNum) {
    return [
      {
        'type': 'seerah',
        'paragraphs': [
          'Chapter $chapterNum content will appear here once the book asset '
              '(assets/books/sealed_nectar_${context.read<BookDownloadService>().language}.json)'
              ' is bundled with the app.',
        ],
      }
    ];
  }

  String _hadithNarrator(Map<String, dynamic> h) {
    final list = h['hadith'] as List? ?? [];
    final lang = context.read<BookDownloadService>().language;
    final entry = list.firstWhere(
          (e) => e is Map && e['lang'] == lang,
          orElse: () => list.firstWhere(
            (e) => e is Map && e['lang'] == 'en',
            orElse: () => list.isNotEmpty ? list.first : null,
          ),
        );
    if (entry == null) return '';
    return (entry as Map)['narrator']?.toString() ?? '';
  }

  String _hadithBody(Map<String, dynamic> h) {
    final list = h['hadith'] as List? ?? [];
    final lang = context.read<BookDownloadService>().language;
    // Show translation in user's language; fall back to English
    final entry = list.firstWhere(
          (e) => e is Map && e['lang'] == lang,
          orElse: () => list.firstWhere(
            (e) => e is Map && e['lang'] == 'en',
            orElse: () => list.isNotEmpty ? list.first : null,
          ),
        );
    if (entry == null) return '';
    return (entry as Map)['body']?.toString() ?? '';
  }

  String _hadithArabic(Map<String, dynamic> h) {
    final list = h['hadith'] as List? ?? [];
    final arEntry = list.firstWhere(
        (e) => e is Map && e['lang'] == 'ar',
        orElse: () => null);
    if (arEntry == null) return '';
    return (arEntry as Map)['body']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<BookDownloadService>();
    final isArabic = svc.language == 'ar';

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        size: 18, color: context.textDim),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.book.title,
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 16,
                                color: context.text)),
                        Text(widget.chapterTitle,
                            style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'sans-serif',
                                color: context.textDim),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.gold),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: _hadiths.length,
                      itemBuilder: (context, i) {
                        final h = _hadiths[i];
                        if (h['type'] == 'seerah') {
                          return _SeerahEntry(entry: h, index: i);
                        }
                        return _HadithEntry(
                          entry: h,
                          index: i,
                          narrator: _hadithNarrator(h),
                          body: _hadithBody(h),
                          arabic: isArabic ? _hadithArabic(h) : '',
                          hadithNumber: h['hadithNumber']?.toString() ??
                              '$_currentChapter:${i + 1}',
                        );
                      },
                    ),
            ),
            // Bottom navigation bar
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                border: Border(top: BorderSide(color: context.border)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Previous
                  GestureDetector(
                    onTap: _currentChapter > 1
                        ? () {
                            setState(() => _currentChapter--);
                            _loadChapter(_currentChapter);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentChapter > 1
                            ? context.surface2
                            : context.surface2.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: Icon(Icons.arrow_back_ios,
                          size: 14,
                          color: _currentChapter > 1
                              ? context.text
                              : context.textDim),
                    ),
                  ),
                  const Spacer(),
                  // Position label
                  Text(
                    '${widget.book.category == BookCategory.hadith ? 'Book' : 'Chapter'}'
                    ' $_currentChapter of ${widget.totalChapters}',
                    style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'sans-serif',
                        color: context.textDim),
                  ),
                  const Spacer(),
                  // Next
                  GestureDetector(
                    onTap: _currentChapter < widget.totalChapters
                        ? () {
                            setState(() => _currentChapter++);
                            _loadChapter(_currentChapter);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentChapter < widget.totalChapters
                            ? context.surface2
                            : context.surface2.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: Icon(Icons.arrow_forward_ios,
                          size: 14,
                          color: _currentChapter < widget.totalChapters
                              ? context.text
                              : context.textDim),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hadith Entry ────────────────────────────────────────────────────────────
class _HadithEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int index;
  final String narrator;
  final String body;
  final String arabic;
  final String hadithNumber;

  const _HadithEntry({
    required this.entry,
    required this.index,
    required this.narrator,
    required this.body,
    required this.arabic,
    required this.hadithNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hadith number badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldDim.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.goldDim.withOpacity(0.3)),
                ),
                child: Text('Hadith $hadithNumber',
                    style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'sans-serif',
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (narrator.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(narrator,
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: context.textDim,
                    fontFamily: 'sans-serif')),
          ],
          if (arabic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 18,
                    height: 2,
                    color: context.arabic)),
            Divider(color: context.border, height: 20),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: context.text)),
          ],
        ],
      ),
    );
  }
}

// ── Seerah Entry ────────────────────────────────────────────────────────────
class _SeerahEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int index;

  const _SeerahEntry({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final paragraphs = (entry['paragraphs'] as List? ?? [])
        .map((p) => p.toString())
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(p,
                      style: TextStyle(
                          fontSize: 14, height: 1.8, color: context.text)),
                ))
            .toList(),
      ),
    );
  }
}
