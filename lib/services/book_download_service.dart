import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show ChangeNotifier, compute, debugPrint;
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

  Future<void> _downloadFromSunnah(IslamicBook book) async {
    final col = book.collectionKey;

    // ── Step 1: English (also contains metadata) ──────────────────────────
    _progress[book.id] = 0.05;
    notifyListeners();

    final String enBody;
    try {
      enBody = await rootBundle.loadString('assets/books/eng-$col.min.json');
    } catch (_) {
      throw Exception('Hadith data for $col is not bundled in this build');
    }
    _progress[book.id] = 0.25;
    notifyListeners();

    final enData = await compute(
        (String s) => jsonDecode(s) as Map<String, dynamic>, enBody);
    final meta = enData['metadata'] as Map<String, dynamic>;
    final sections = (meta['sections'] as Map<String, dynamic>?) ?? {};
    final sectionDetails =
        (meta['section_details'] as Map<String, dynamic>?) ?? {};

    // Build hadith-number → 1-indexed section lookup
    final hadithSection = <int, int>{};
    for (final e in sectionDetails.entries) {
      final sNum = (int.tryParse(e.key) ?? 0) + 1;
      final d = e.value as Map<String, dynamic>;
      final first = (d['hadithnumber_first'] as num?)?.toInt() ?? 0;
      final last = (d['hadithnumber_last'] as num?)?.toInt() ?? 0;
      for (int i = first; i <= last; i++) {
        hadithSection[i] = sNum;
      }
    }

    // Write small index file (books list only)
    final books = sections.entries.map((e) {
      final sectionKey = int.tryParse(e.key) ?? 0;
      final detail = sectionDetails[e.key] as Map<String, dynamic>?;
      final first = (detail?['hadithnumber_first'] as num?)?.toInt() ?? 0;
      final last = (detail?['hadithnumber_last'] as num?)?.toInt() ?? 0;
      return {
        'bookNumber': sectionKey + 1,
        'book': [
          {'lang': 'en', 'name': e.value.toString()}
        ],
        'hadithsCount': (last - first + 1).clamp(0, 9999),
      };
    }).toList()
      ..sort((a, b) =>
          (a['bookNumber'] as int).compareTo(b['bookNumber'] as int));

    final title = meta['name']?.toString() ?? book.title;
    await File(await _bookIndexPath(book.id)).writeAsString(jsonEncode({
      'title': title,
      'collection': col,
      'source': 'fawazahmed0_v2',
      'books': books,
    }));

    // Save English hadiths grouped by section
    await _saveHadithsBySection(
        enData['hadiths'] as List, hadithSection, 'en', book.id);
    _progress[book.id] = 0.50;
    notifyListeners();

    // ── Step 2: Arabic ─────────────────────────────────────────────────────
    try {
      final arBody =
          await rootBundle.loadString('assets/books/ara-$col.min.json');
      final arData = await compute(
          (String s) => jsonDecode(s) as Map<String, dynamic>, arBody);
      await _saveHadithsBySection(
          arData['hadiths'] as List, hadithSection, 'ar', book.id);
    } catch (_) {}
    _progress[book.id] = 0.75;
    notifyListeners();

    // ── Step 3: Urdu ───────────────────────────────────────────────────────
    try {
      final urBody =
          await rootBundle.loadString('assets/books/urd-$col.min.json');
      final urData = await compute(
          (String s) => jsonDecode(s) as Map<String, dynamic>, urBody);
      await _saveHadithsBySection(
          urData['hadiths'] as List, hadithSection, 'ur', book.id);
    } catch (_) {}
    _progress[book.id] = 0.95;
    notifyListeners();
  }

  /// Groups hadiths by 1-indexed section number and writes to a per-language file.
  Future<void> _saveHadithsBySection(
    List hadiths,
    Map<int, int> hadithSection,
    String lang,
    String bookId,
  ) async {
    final bySection = <String, List<Map<String, dynamic>>>{};
    for (final h in hadiths) {
      if (h is! Map) continue;
      final hadithNum = (h['hadithnumber'] as num?)?.toInt() ?? 0;
      final sNum = hadithSection[hadithNum] ?? 0;
      if (sNum == 0) continue;
      bySection.putIfAbsent(sNum.toString(), () => []).add({
        'hadithNumber': hadithNum.toString(),
        'hadith': [
          {
            'lang': lang,
            'narrator': h['narrator']?.toString() ?? '',
            'body': h['text']?.toString() ?? '',
          }
        ],
      });
    }
    await File(await _bookLangPath(bookId, lang)).writeAsString(jsonEncode({
      'source': 'fawazahmed0_v2',
      'lang': lang,
      'sections': bySection,
    }));
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
