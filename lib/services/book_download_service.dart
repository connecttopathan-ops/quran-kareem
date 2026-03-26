import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/islamic_book.dart';

enum BookDownloadState { notDownloaded, downloading, downloaded, failed }

class BookDownloadService extends ChangeNotifier {
  final Map<String, BookDownloadState> _states = {};
  final Map<String, double> _progress = {};
  final Map<String, String> _errors = {};
  String _language = 'en';

  BookDownloadService() {
    _init();
  }

  String get language => _language;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('books_language') ?? 'en';
    for (final book in kIslamicBooks) {
      final downloaded = prefs.getBool('book_${book.id}_downloaded') ?? false;
      _states[book.id] =
          downloaded ? BookDownloadState.downloaded : BookDownloadState.notDownloaded;
    }
    notifyListeners();
  }

  BookDownloadState stateFor(String bookId) =>
      _states[bookId] ?? BookDownloadState.notDownloaded;

  double progressFor(String bookId) => _progress[bookId] ?? 0.0;

  String? errorFor(String bookId) => _errors[bookId];

  bool get hasAnyProgress => kIslamicBooks.any((b) {
        final pos = _cachedPositions[b.id];
        return pos != null && pos.isNotEmpty;
      });

  final Map<String, String?> _cachedPositions = {};

  Future<void> loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    for (final book in kIslamicBooks) {
      _cachedPositions[book.id] = prefs.getString('book_${book.id}_last_position');
    }
    notifyListeners();
  }

  String? cachedPositionFor(String bookId) => _cachedPositions[bookId];

  IslamicBook? get mostRecentBook {
    IslamicBook? result;
    for (final book in kIslamicBooks) {
      final pos = _cachedPositions[book.id];
      if (pos != null && pos.isNotEmpty) {
        result = book;
        break;
      }
    }
    return result;
  }

  Future<void> setLanguage(String langCode) async {
    _language = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('books_language', langCode);
    notifyListeners();
  }

  Future<String> _bookFilePath(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/books/$bookId.json';
  }

  /// Separate small index file — just the books list, no hadith content.
  Future<String> _bookIndexPath(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/books/${bookId}_index.json';
  }

  /// Per-language hadith file — hadiths pre-grouped by section number.
  Future<String> _bookLangPath(String bookId, String lang) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/books/${bookId}_$lang.json';
  }

  Future<bool> isFileDownloaded(String bookId) async {
    try {
      final path = await _bookFilePath(bookId);
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> startDownload(IslamicBook book) async {
    if (_states[book.id] == BookDownloadState.downloading) return;
    _errors.remove(book.id);
    _states[book.id] = BookDownloadState.downloading;
    _progress[book.id] = 0.0;
    notifyListeners();

    try {
      final dir = Directory(
          '${(await getApplicationDocumentsDirectory()).path}/books');
      if (!await dir.exists()) await dir.create(recursive: true);

      if (book.isLocal) {
        await _downloadLocalAsset(book);
      } else {
        await _downloadFromSunnah(book);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('book_${book.id}_downloaded', true);
      _states[book.id] = BookDownloadState.downloaded;
      _progress[book.id] = 1.0;
    } catch (e, stack) {
      debugPrint('BookDownload error for ${book.id}: $e\n$stack');
      _states[book.id] = BookDownloadState.failed;
      _progress[book.id] = 0.0;
      _errors[book.id] = e.toString();
    }
    notifyListeners();
  }

  Future<void> _downloadLocalAsset(IslamicBook book) async {
    final assetKey = book.collectionKey.replaceFirst('local:', '');
    final assetPath = 'assets/books/${assetKey}_$_language.json';
    String content;
    try {
      content = await rootBundle.loadString(assetPath);
    } catch (_) {
      // Asset not bundled yet — store empty placeholder
      content = jsonEncode({'title': book.title, 'chapters': [], 'lang': _language});
    }
    final path = await _bookFilePath(book.id);
    await File(path).writeAsString(content);
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      _progress[book.id] = i / 10;
      notifyListeners();
    }
  }

  static const _kHadithApiKey =
      r'$2y$10$i0Y8DwcA9IKOd9kM0for4eX6RGOOAFQ9Mvd8etx5p2UDWZH8rNK6';

  Future<void> _downloadFromSunnah(IslamicBook book) async {
    final slug = book.collectionKey; // e.g. 'sahih-bukhari'
    const timeout = Duration(seconds: 60);

    // ── Step 1: Chapter list ──────────────────────────────────────────────
    _progress[book.id] = 0.02;
    notifyListeners();

    final chapResp = await http
        .get(Uri.https('hadithapi.com', '/api/$slug/chapters',
            {'apiKey': _kHadithApiKey}))
        .timeout(timeout);
    if (chapResp.statusCode != 200) {
      throw Exception('Chapter list fetch failed (${chapResp.statusCode})');
    }

    final chapJson = jsonDecode(chapResp.body) as Map<String, dynamic>;
    final chapters =
        (chapJson['chapters'] as List).cast<Map<String, dynamic>>();

    final indexBooks = chapters.map((ch) {
      final chNum = int.tryParse(ch['chapterNumber'].toString()) ?? 0;
      return {
        'bookNumber': chNum,
        'book': [
          {'lang': 'en', 'name': ch['chapterEnglish']?.toString() ?? ''},
          {'lang': 'ar', 'name': ch['chapterArabic']?.toString() ?? ''},
        ],
        'hadithsCount': int.tryParse(ch['hadithCount'].toString()) ?? 0,
      };
    }).toList()
      ..sort((a, b) =>
          (a['bookNumber'] as int).compareTo(b['bookNumber'] as int));

    await File(await _bookIndexPath(book.id)).writeAsString(jsonEncode({
      'title': book.title,
      'collection': slug,
      'source': 'hadithapi_v1',
      'books': indexBooks,
    }));

    _progress[book.id] = 0.05;
    notifyListeners();

    // ── Step 2: Hadiths per chapter ───────────────────────────────────────
    final enSections = <String, List<Map<String, dynamic>>>{};
    final arSections = <String, List<Map<String, dynamic>>>{};
    final urSections = <String, List<Map<String, dynamic>>>{};

    final total = chapters.length;
    for (int i = 0; i < total; i++) {
      final ch = chapters[i];
      final chNum = int.tryParse(ch['chapterNumber'].toString()) ?? 0;
      final chKey = chNum.toString();

      int page = 1;
      while (true) {
        final hResp = await http
            .get(Uri.https('hadithapi.com', '/api/hadiths', {
              'apiKey': _kHadithApiKey,
              'book': slug,
              'chapter': chKey,
              'paginate': '100',
              'page': page.toString(),
            }))
            .timeout(timeout);
        if (hResp.statusCode != 200) break;

        final hJson = jsonDecode(hResp.body) as Map<String, dynamic>;
        final paged = hJson['hadiths'] as Map<String, dynamic>;
        final hadiths = (paged['data'] as List).cast<Map<String, dynamic>>();
        final lastPage = int.tryParse(paged['last_page'].toString()) ?? 1;

        for (final h in hadiths) {
          final hNum = h['hadithNumber']?.toString() ?? '';
          final narrator = h['englishNarrator']?.toString() ?? '';

          final enBody = h['hadithEnglish']?.toString() ?? '';
          if (enBody.isNotEmpty) {
            enSections.putIfAbsent(chKey, () => []).add({
              'hadithNumber': hNum,
              'hadith': [
                {'lang': 'en', 'narrator': narrator, 'body': enBody}
              ],
            });
          }

          final arBody = h['hadithArabic']?.toString() ?? '';
          if (arBody.isNotEmpty) {
            arSections.putIfAbsent(chKey, () => []).add({
              'hadithNumber': hNum,
              'hadith': [
                {'lang': 'ar', 'narrator': narrator, 'body': arBody}
              ],
            });
          }

          final urBody = h['hadithUrdu']?.toString() ?? '';
          if (urBody.isNotEmpty) {
            urSections.putIfAbsent(chKey, () => []).add({
              'hadithNumber': hNum,
              'hadith': [
                {'lang': 'ur', 'narrator': narrator, 'body': urBody}
              ],
            });
          }
        }

        if (page >= lastPage) break;
        page++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _progress[book.id] = 0.05 + 0.93 * (i + 1) / total;
      notifyListeners();
    }

    // ── Step 3: Write lang files ──────────────────────────────────────────
    await Future.wait([
      File(await _bookLangPath(book.id, 'en')).writeAsString(jsonEncode({
        'source': 'hadithapi_v1',
        'lang': 'en',
        'sections': enSections,
      })),
      File(await _bookLangPath(book.id, 'ar')).writeAsString(jsonEncode({
        'source': 'hadithapi_v1',
        'lang': 'ar',
        'sections': arSections,
      })),
      File(await _bookLangPath(book.id, 'ur')).writeAsString(jsonEncode({
        'source': 'hadithapi_v1',
        'lang': 'ur',
        'sections': urSections,
      })),
    ]);
  }

  Future<List<Map<String, dynamic>>> loadChapterIndex(IslamicBook book) async {
    try {
      // Try the small index file first (fast path for hadith books)
      final indexPath = await _bookIndexPath(book.id);
      final indexFile = File(indexPath);
      if (await indexFile.exists()) {
        final data =
            jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
        if (data.containsKey('books')) {
          return (data['books'] as List).cast<Map<String, dynamic>>();
        }
      }
      // Fall back to full data file (seerah books / legacy downloads)
      final path = await _bookFilePath(book.id);
      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data.containsKey('books')) {
        return (data['books'] as List).cast<Map<String, dynamic>>();
      }
      if (data.containsKey('chapters')) {
        return (data['chapters'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Load a single seerah chapter by number (1-indexed).
  /// Returns a list with one entry containing `type: 'seerah'` and `paragraphs`.
  Future<List<Map<String, dynamic>>> loadSeerahChapter(
      IslamicBook book, int chapterNumber) async {
    try {
      final path = await _bookFilePath(book.id);
      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final chapters = data['chapters'] as List? ?? [];
      // chapters are 1-indexed via the 'number' field
      final ch = chapters.firstWhere(
        (c) => c is Map && (c['number'] == chapterNumber),
        orElse: () => null,
      );
      if (ch != null && ch['content'] != null) {
        final text = ch['content'].toString();
        // Split into paragraphs of ~500 chars at sentence boundaries for readability
        final sentences = text.split(RegExp(r'(?<=[.?!])\s+'));
        final paragraphs = <String>[];
        final buf = StringBuffer();
        for (final s in sentences) {
          buf.write(s);
          buf.write(' ');
          if (buf.length >= 500) {
            paragraphs.add(buf.toString().trim());
            buf.clear();
          }
        }
        if (buf.isNotEmpty) paragraphs.add(buf.toString().trim());
        return [
          {'type': 'seerah', 'paragraphs': paragraphs}
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> loadHadiths(
      IslamicBook book, int bookNumber, {int page = 1}) async {
    if (book.isLocal) return [];
    try {
      // Try user's language file, fall back to English
      for (final lang in [_language, 'en']) {
        final path = await _bookLangPath(book.id, lang);
        final file = File(path);
        if (!await file.exists()) continue;
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (data['source'] != 'fawazahmed0_v2' &&
            data['source'] != 'hadithapi_v1') continue;
        final sections = data['sections'] as Map<String, dynamic>? ?? {};
        final all = (sections[bookNumber.toString()] as List? ?? [])
            .whereType<Map>()
            .where((h) {
              final entries = h['hadith'] as List? ?? [];
              return entries.any(
                  (e) => e is Map && (e['body'] as String? ?? '').isNotEmpty);
            })
            .cast<Map<String, dynamic>>()
            .toList();
        const pageSize = 20;
        final start = (page - 1) * pageSize;
        if (start >= all.length) return [];
        return all.sublist(start, (start + pageSize).clamp(0, all.length));
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteBook(String bookId) async {
    try {
      for (final path in [
        await _bookFilePath(bookId),
        await _bookIndexPath(bookId),
        await _bookLangPath(bookId, 'en'),
        await _bookLangPath(bookId, 'ar'),
        await _bookLangPath(bookId, 'ur'),
      ]) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('book_${bookId}_downloaded', false);
    await prefs.remove('book_${bookId}_last_position');
    await prefs.remove('book_${bookId}_progress');
    _states[bookId] = BookDownloadState.notDownloaded;
    _progress[bookId] = 0.0;
    _cachedPositions[bookId] = null;
    notifyListeners();
  }

  Future<String?> getLastPosition(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('book_${bookId}_last_position');
  }

  Future<void> savePosition(String bookId, String position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_${bookId}_last_position', position);
    _cachedPositions[bookId] = position;
    notifyListeners();
  }

  Future<double> getReadingProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('book_${bookId}_progress') ?? 0.0;
  }

  Future<void> saveReadingProgress(String bookId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('book_${bookId}_progress', progress);
    notifyListeners();
  }

  Future<bool> wasPromptShown(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('book_${bookId}_download_prompt_shown') ?? false;
  }

  Future<void> markPromptShown(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('book_${bookId}_download_prompt_shown', true);
  }

  List<IslamicBook> get downloadedBooks => kIslamicBooks
      .where((b) => _states[b.id] == BookDownloadState.downloaded)
      .toList();
}
