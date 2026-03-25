import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/islamic_book.dart';
import '../services/book_download_service.dart';
import 'book_detail_screen.dart';
import 'book_language_screen.dart';

class IslamicBooksScreen extends StatefulWidget {
  const IslamicBooksScreen({super.key});

  @override
  State<IslamicBooksScreen> createState() => _IslamicBooksScreenState();
}

class _IslamicBooksScreenState extends State<IslamicBooksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLanguagePicker();
    });
  }

  Future<void> _maybeShowLanguagePicker() async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getBool('books_language_set') ?? false;
    if (!set && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const BookLanguageScreen(),
            fullscreenDialog: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookDownloadService>(
      builder: (context, svc, _) {
        final langLabel =
            svc.language == 'ar' ? 'AR' : svc.language == 'ur' ? 'UR' : 'EN';

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
                        child: Text('Islamic Books',
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 20,
                                color: context.text)),
                      ),
                      // Language pill
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BookLanguageScreen(),
                              fullscreenDialog: true),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldDim.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.goldDim.withOpacity(0.4)),
                          ),
                          child: Text(langLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'sans-serif',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      _BookSection(
                        label: 'Hadith',
                        books: kIslamicBooks
                            .where((b) => b.category == BookCategory.hadith)
                            .toList(),
                        svc: svc,
                      ),
                      const SizedBox(height: 8),
                      _BookSection(
                        label: 'Seerah',
                        books: kIslamicBooks
                            .where((b) => b.category == BookCategory.seerah)
                            .toList(),
                        svc: svc,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────
class _BookSection extends StatelessWidget {
  final String label;
  final List<IslamicBook> books;
  final BookDownloadService svc;

  const _BookSection(
      {required this.label, required this.books, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: context.textDim,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w600)),
        ),
        ...books.map((book) => _BookCard(book: book, svc: svc)),
      ],
    );
  }
}

// ── Book Card ──────────────────────────────────────────────────────────────
class _BookCard extends StatefulWidget {
  final IslamicBook book;
  final BookDownloadService svc;

  const _BookCard({required this.book, required this.svc});

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await widget.svc.getReadingProgress(widget.book.id);
    if (mounted) setState(() => _progress = p);
  }

  Future<void> _handleTap(BuildContext context) async {
    final state = widget.svc.stateFor(widget.book.id);
    if (state == BookDownloadState.notDownloaded) {
      final shown = await widget.svc.wasPromptShown(widget.book.id);
      if (!shown && context.mounted) {
        await _showDownloadSheet(context);
      }
      return;
    }
    if (state == BookDownloadState.downloaded && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: widget.book)),
      );
    }
  }

  Future<void> _showDownloadSheet(BuildContext context) async {
    await widget.svc.markPromptShown(widget.book.id);
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DownloadSheet(book: widget.book, svc: widget.svc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.svc.stateFor(widget.book.id);
    final dlProgress = widget.svc.progressFor(widget.book.id);
    final hasProgress = _progress > 0;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Spine
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: widget.book.spineColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(11)),
              ),
              child: Center(
                child: Text(widget.book.spineChar,
                    style: const TextStyle(
                        fontFamily: 'Scheherazade',
                        fontSize: 24,
                        color: AppColors.gold)),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.book.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.text)),
                        ),
                        if (state == BookDownloadState.downloaded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldDim.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.download_done,
                                size: 12, color: AppColors.gold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.book.author,
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'sans-serif',
                            color: context.textDim)),
                    Text(widget.book.metaLine,
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'sans-serif',
                            color: context.textDim)),
                    const SizedBox(height: 10),
                    // Progress bar (reading)
                    if (hasProgress) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 3,
                          backgroundColor: context.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // State button
                    _StateButton(
                      book: widget.book,
                      state: state,
                      dlProgress: dlProgress,
                      hasReadingProgress: hasProgress,
                      svc: widget.svc,
                      onNavigate: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BookDetailScreen(book: widget.book)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State Button ────────────────────────────────────────────────────────────
class _StateButton extends StatelessWidget {
  final IslamicBook book;
  final BookDownloadState state;
  final double dlProgress;
  final bool hasReadingProgress;
  final BookDownloadService svc;
  final VoidCallback onNavigate;

  const _StateButton({
    required this.book,
    required this.state,
    required this.dlProgress,
    required this.hasReadingProgress,
    required this.svc,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BookDownloadState.notDownloaded:
        return _outlinedBtn(
          context,
          label: 'Download to read',
          icon: Icons.download_outlined,
          onTap: () async {
            final shown = await svc.wasPromptShown(book.id);
            if (!shown) {
              await svc.markPromptShown(book.id);
              if (context.mounted) {
                await showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _DownloadSheet(book: book, svc: svc),
                );
              }
            } else {
              svc.startDownload(book);
            }
          },
        );

      case BookDownloadState.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: dlProgress,
                minHeight: 4,
                backgroundColor: context.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
                'Downloading ${(dlProgress * 100).toStringAsFixed(0)}%'
                ' · ${(book.fileSizeMb * dlProgress).toStringAsFixed(1)} /'
                ' ${book.fileSizeMb.toStringAsFixed(1)} MB',
                style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'sans-serif',
                    color: context.textDim)),
          ],
        );

      case BookDownloadState.downloaded:
        return _goldBtn(
          context,
          label: hasReadingProgress ? 'Continue reading →' : 'Start reading',
          onTap: onNavigate,
        );
    }
  }

  Widget _outlinedBtn(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: context.textDim),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'sans-serif',
                    color: context.textDim)),
          ],
        ),
      ),
    );
  }

  Widget _goldBtn(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontFamily: 'sans-serif',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}

// ── Download Sheet ─────────────────────────────────────────────────────────
class _DownloadSheet extends StatelessWidget {
  final IslamicBook book;
  final BookDownloadService svc;

  const _DownloadSheet({required this.book, required this.svc});

  @override
  Widget build(BuildContext context) {
    final langName = svc.language == 'ar'
        ? 'Arabic'
        : svc.language == 'ur'
            ? 'Urdu'
            : 'English';

    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(book.title,
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  color: context.text)),
          const SizedBox(height: 8),
          Text(
              'This book will be saved on your device for offline reading.'
              ' You\'ll only be asked once.',
              style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'sans-serif',
                  color: context.textDim)),
          const SizedBox(height: 14),
          Row(children: [
            _InfoChip(label: '${book.fileSizeMb.toStringAsFixed(1)} MB'),
            const SizedBox(width: 8),
            _InfoChip(label: langName),
            const SizedBox(width: 8),
            _InfoChip(label: book.metaLine),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textDim,
                  side: BorderSide(color: context.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Not now'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  svc.startDownload(book);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 44),
                  elevation: 0,
                ),
                child: const Text('Download'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
    );
  }
}
