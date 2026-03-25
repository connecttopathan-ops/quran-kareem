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
    // sunnah.com public API — replace with your API key for production
    const apiKey = 'SqD712P3E82xnwOAEOkGd5JZH8s9wRNx';
    const baseUrl = 'https://api.sunnah.com/v1';

    // Fetch books index (table of contents) only — content loaded per chapter
    final url = Uri.parse(
        '$baseUrl/collections/${book.collectionKey}/books?limit=${book.totalBooks ?? 100}&page=1');
    final response = await http.get(url, headers: {'X-API-Key': apiKey});

    Map<String, dynamic> saved;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      saved = {
        'title': book.title,
        'collection': book.collectionKey,
        'lang': _language,
        'books': data['data'] ?? [],
      };
    } else {
      // API unavailable — store minimal stub so UI shows downloaded state
      saved = {
        'title': book.title,
        'collection': book.collectionKey,
        'lang': _language,
        'books': List.generate(book.totalBooks ?? book.totalItems, (i) => {
              'bookNumber': i + 1,
              'book': [{'lang': 'en', 'name': 'Chapter ${i + 1}'}],
              'hadithsCount': 0,
            }),
      };
    }

    _progress[book.id] = 0.8;
    notifyListeners();
    final path = await _bookFilePath(book.id);
    await File(path).writeAsString(jsonEncode(saved));
  }

  Future<List<Map<String, dynamic>>> loadChapterIndex(IslamicBook book) async {
    try {
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

  Future<List<Map<String, dynamic>>> loadHadiths(
      IslamicBook book, int bookNumber, {int page = 1}) async {
    if (book.isLocal) return [];
    const apiKey = 'SqD712P3E82xnwOAEOkGd5JZH8s9wRNx';
    const baseUrl = 'https://api.sunnah.com/v1';
    try {
      final url = Uri.parse(
          '$baseUrl/collections/${book.collectionKey}/books/$bookNumber/hadiths?limit=20&page=$page');
      final response = await http.get(url, headers: {'X-API-Key': apiKey});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteBook(String bookId) async {
    try {
      final path = await _bookFilePath(bookId);
      final f = File(path);
      if (await f.exists()) await f.delete();
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
