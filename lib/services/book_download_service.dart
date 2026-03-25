import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/islamic_book.dart';

enum BookDownloadState { notDownloaded, downloading, downloaded }

class BookDownloadService extends ChangeNotifier {
  final Map<String, BookDownloadState> _states = {};
  final Map<String, double> _progress = {};
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
    } catch (e) {
      _states[book.id] = BookDownloadState.notDownloaded;
      _progress[book.id] = 0.0;
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
    const base =
        'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
    final col = book.collectionKey;

    _progress[book.id] = 0.05;
    notifyListeners();

    const timeout = Duration(seconds: 60);
    final enResp = await http
        .get(Uri.parse('$base/eng-$col.min.json'))
        .timeout(timeout);
    _progress[book.id] = 0.35;
    notifyListeners();

    final arResp = await http
        .get(Uri.parse('$base/ara-$col.min.json'))
        .timeout(timeout);
    _progress[book.id] = 0.60;
    notifyListeners();

    final urResp = await http
        .get(Uri.parse('$base/urd-$col.min.json'))
        .timeout(timeout);
    _progress[book.id] = 0.80;
    notifyListeners();

    if (enResp.statusCode != 200) {
      throw Exception('Download failed (${enResp.statusCode})');
    }

    final enData = jsonDecode(enResp.body) as Map<String, dynamic>;
    final arData = arResp.statusCode == 200
        ? jsonDecode(arResp.body) as Map<String, dynamic>
        : null;
    final urData = urResp.statusCode == 200
        ? jsonDecode(urResp.body) as Map<String, dynamic>
        : null;

    final meta = enData['metadata'] as Map<String, dynamic>;
    final sections = (meta['sections'] as Map<String, dynamic>?) ?? {};
    final sectionDetails =
        (meta['section_details'] as Map<String, dynamic>?) ?? {};

    // Build books list (table of contents) — 1-indexed so no "Book 0"
    final books = sections.entries.map((e) {
      final sectionKey = int.tryParse(e.key) ?? 0;
      final detail = sectionDetails[e.key] as Map<String, dynamic>?;
      final first = detail?['hadithnumber_first'] as int? ?? 0;
      final last = detail?['hadithnumber_last'] as int? ?? 0;
      return {
        'bookNumber': sectionKey + 1, // 1-indexed
        'book': [
          {'lang': 'en', 'name': e.value.toString()}
        ],
        'hadithsCount': (last - first + 1).clamp(0, 9999),
      };
    }).toList()
      ..sort((a, b) =>
          (a['bookNumber'] as int).compareTo(b['bookNumber'] as int));

    // Build hadith-number → section-number lookup (1-indexed)
    final hadithSection = <int, int>{};
    for (final e in sectionDetails.entries) {
      final sNum = (int.tryParse(e.key) ?? 0) + 1; // 1-indexed
      final d = e.value as Map<String, dynamic>;
      final first = d['hadithnumber_first'] as int? ?? 0;
      final last = d['hadithnumber_last'] as int? ?? 0;
      for (int i = first; i <= last; i++) {
        hadithSection[i] = sNum;
      }
    }

    // Build per-language lookup maps
    Map<int, dynamic> _buildMap(Map<String, dynamic>? data) {
      final map = <int, dynamic>{};
      if (data == null) return map;
      for (final h in (data['hadiths'] as List? ?? [])) {
        if (h is Map) map[h['hadithnumber'] as int] = h;
      }
      return map;
    }

    final arMap = _buildMap(arData);
    final urMap = _buildMap(urData);

    // Merge English + Arabic + Urdu hadiths
    final hadiths = (enData['hadiths'] as List? ?? []).map((h) {
      final num = h['hadithnumber'] as int;
      final entries = <Map<String, dynamic>>[
        {
          'lang': 'en',
          'narrator': h['narrator']?.toString() ?? '',
          'body': h['text']?.toString() ?? '',
        },
      ];
      final arH = arMap[num];
      if (arH != null) {
        entries.add({
          'lang': 'ar',
          'narrator': arH['narrator']?.toString() ?? '',
          'body': arH['text']?.toString() ?? '',
        });
      }
      final urH = urMap[num];
      if (urH != null) {
        entries.add({
          'lang': 'ur',
          'narrator': urH['narrator']?.toString() ?? '',
          'body': urH['text']?.toString() ?? '',
        });
      }
      return {
        'hadithNumber': num.toString(),
        'sectionNumber': hadithSection[num] ?? 0,
        'hadith': entries,
      };
    }).toList();

    final title = meta['name']?.toString() ?? book.title;

    // Write small index file (books list only) — loaded by BookDetailScreen
    final indexData = {
      'title': title,
      'collection': col,
      'source': 'fawazahmed0',
      'books': books,
    };
    final indexPath = await _bookIndexPath(book.id);
    await File(indexPath).writeAsString(jsonEncode(indexData));

    // Write full data file (hadiths) — loaded per-chapter by reader
    final saved = {
      'title': title,
      'collection': col,
      'source': 'fawazahmed0',
      'hadiths': hadiths,
    };

    _progress[book.id] = 0.92;
    notifyListeners();
    final path = await _bookFilePath(book.id);
    await File(path).writeAsString(jsonEncode(saved));
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
      final path = await _bookFilePath(book.id);
      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['source'] == 'fawazahmed0') {
        final all = (data['hadiths'] as List? ?? [])
            .whereType<Map>()
            .where((h) => h['sectionNumber'] == bookNumber)
            .where((h) {
              // Skip hadiths with no text in any language
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
      final path = await _bookFilePath(bookId);
      final f = File(path);
      if (await f.exists()) await f.delete();
      final indexPath = await _bookIndexPath(bookId);
      final fi = File(indexPath);
      if (await fi.exists()) await fi.delete();
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
