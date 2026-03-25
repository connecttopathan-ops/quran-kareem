import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/islamic_book.dart';
import '../services/book_download_service.dart';
import 'book_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final IslamicBook book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = true;
  String? _lastPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<BookDownloadService>();
    final chapters = await svc.loadChapterIndex(widget.book);
    final pos = await svc.getLastPosition(widget.book.id);
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _loading = false;
        _lastPosition = pos;
      });
    }
  }

  String _chapterTitle(Map<String, dynamic> chapter, int fallbackIndex) {
    // sunnah.com returns book.book as a list of {lang, name}
    if (chapter.containsKey('book') && chapter['book'] is List) {
      final books = chapter['book'] as List;
      final match = books.firstWhere(
        (b) => b is Map && b['lang'] == 'en',
        orElse: () => books.isNotEmpty ? books.first : null,
      );
      if (match != null && match is Map && match['name'] != null) {
        return match['name'].toString();
      }
    }
    if (chapter.containsKey('name')) return chapter['name'].toString();
    if (chapter.containsKey('title')) return chapter['title'].toString();
    return '${widget.book.category == BookCategory.hadith ? 'Book' : 'Chapter'} ${fallbackIndex + 1}';
  }

  int _chapterNumber(Map<String, dynamic> chapter, int fallbackIndex) {
    if (chapter.containsKey('bookNumber')) {
      return int.tryParse(chapter['bookNumber'].toString()) ?? fallbackIndex + 1;
    }
    if (chapter.containsKey('number')) {
      return int.tryParse(chapter['number'].toString()) ?? fallbackIndex + 1;
    }
    return fallbackIndex + 1;
  }

  int _hadithCount(Map<String, dynamic> chapter) {
    if (chapter.containsKey('hadithsCount')) {
      return int.tryParse(chapter['hadithsCount'].toString()) ?? 0;
    }
    return 0;
  }

  bool _isRead(int chapterNum) {
    if (_lastPosition == null) return false;
    final parts = _lastPosition!.split(':');
    if (parts.isEmpty) return false;
    final readChapter = int.tryParse(parts[0]) ?? 0;
    return chapterNum < readChapter;
  }

  bool _isCurrent(int chapterNum) {
    if (_lastPosition == null) return false;
    final parts = _lastPosition!.split(':');
    if (parts.isEmpty) return false;
    return int.tryParse(parts[0]) == chapterNum;
  }

  // Fallback chapter list when download is empty
  List<Map<String, dynamic>> get _effectiveChapters {
    if (_chapters.isNotEmpty) return _chapters;
    final count = widget.book.totalBooks ?? widget.book.totalItems;
    return List.generate(
        count,
        (i) => {
              'bookNumber': i + 1,
              'book': [
                {
                  'lang': 'en',
                  'name':
                      '${widget.book.category == BookCategory.hadith ? 'Book' : 'Chapter'} ${i + 1}'
                }
              ],
            });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _effectiveChapters;
    final label =
        widget.book.category == BookCategory.hadith ? 'books' : 'chapters';

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
                                fontSize: 18,
                                color: context.text)),
                        Text('${chapters.length} $label',
                            style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'sans-serif',
                                color: context.textDim)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, size: 20, color: context.textDim),
                    onPressed: () => showSearch(
                      context: context,
                      delegate: _ChapterSearchDelegate(
                          chapters: chapters,
                          book: widget.book,
                          onSelect: _openChapter),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Chapter list
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: chapters.length,
                      itemBuilder: (context, i) {
                        final ch = chapters[i];
                        final num = _chapterNumber(ch, i);
                        final title = _chapterTitle(ch, i);
                        final count = _hadithCount(ch);
                        final read = _isRead(num);
                        final current = _isCurrent(num);

                        return GestureDetector(
                          onTap: () => _openChapter(num, title),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: current
                                      ? AppColors.gold
                                      : context.border),
                            ),
                            child: Row(
                              children: [
                                // Chapter number badge
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: current
                                        ? AppColors.gold.withOpacity(0.12)
                                        : context.surface2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: current
                                            ? AppColors.gold.withOpacity(0.5)
                                            : context.border),
                                  ),
                                  child: Center(
                                    child: Text('$num',
                                        style: TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 12,
                                            color: current
                                                ? AppColors.gold
                                                : context.textDim)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: current
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: context.text)),
                                      if (count > 0)
                                        Text(
                                            '$count ${widget.book.category == BookCategory.hadith ? 'hadiths' : 'passages'}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontFamily: 'sans-serif',
                                                color: context.textDim)),
                                    ],
                                  ),
                                ),
                                // Read indicator
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: read
                                        ? AppColors.gold
                                        : Colors.transparent,
                                    border: read
                                        ? null
                                        : Border.all(color: context.border),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right,
                                    size: 16, color: context.textDim),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChapter(int chapterNum, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(
          book: widget.book,
          chapterNumber: chapterNum,
          chapterTitle: title,
          totalChapters: _effectiveChapters.length,
        ),
      ),
    ).then((_) => _load()); // refresh position on return
  }
}

// ── Search Delegate ────────────────────────────────────────────────────────
class _ChapterSearchDelegate extends SearchDelegate<void> {
  final List<Map<String, dynamic>> chapters;
  final IslamicBook book;
  final void Function(int num, String title) onSelect;

  _ChapterSearchDelegate(
      {required this.chapters, required this.book, required this.onSelect});

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back_ios, size: 18),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final filtered = chapters.where((ch) {
      if (ch.containsKey('book') && ch['book'] is List) {
        final books = ch['book'] as List;
        return books.any((b) =>
            b is Map && b['name'].toString().toLowerCase().contains(q));
      }
      return ch['name']?.toString().toLowerCase().contains(q) ?? false;
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final ch = filtered[i];
        String title = 'Chapter';
        int num = i + 1;
        if (ch.containsKey('book') && ch['book'] is List) {
          final books = ch['book'] as List;
          final match = books.firstWhere(
              (b) => b is Map && b['lang'] == 'en',
              orElse: () => books.isNotEmpty ? books.first : null);
          if (match != null) title = match['name'].toString();
        }
        if (ch.containsKey('bookNumber')) {
          num = int.tryParse(ch['bookNumber'].toString()) ?? num;
        }
        return ListTile(
          title: Text(title),
          onTap: () {
            close(context, null);
            onSelect(num, title);
          },
        );
      },
    );
  }
}
