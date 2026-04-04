import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/quran_data.dart';
import 'audio_service.dart';

class AudioDownloadService extends ChangeNotifier {
  static final AudioDownloadService _instance =
      AudioDownloadService._internal();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._internal();

  // Progress 0.0–1.0 for active downloads, key = 'reciterId/surahNumber'
  final Map<String, double> _progress = {};

  // Fully downloaded surahs, key = 'reciterId/surahNumber'
  final Set<String> _downloaded = {};

  // Cancellation flags
  final Map<String, bool> _cancelled = {};

  bool isDownloaded(String reciterId, int surahNumber) =>
      _downloaded.contains('$reciterId/$surahNumber');

  bool isDownloading(String reciterId, int surahNumber) =>
      _progress.containsKey('$reciterId/$surahNumber');

  double progress(String reciterId, int surahNumber) =>
      _progress['$reciterId/$surahNumber'] ?? 0.0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('downloaded_audio_surahs') ?? [];
    _downloaded.addAll(saved);
    // Verify files actually exist — clean up stale entries
    final toRemove = <String>{};
    for (final key in _downloaded) {
      final parts = key.split('/');
      if (parts.length < 2) { toRemove.add(key); continue; }
      final reciterId = parts[0];
      final surahNumber = int.tryParse(parts[1]);
      if (surahNumber == null) { toRemove.add(key); continue; }
      final surah = kSurahs.firstWhere((s) => s.number == surahNumber,
          orElse: () => kSurahs.first);
      final offset = surahVerseOffset(surahNumber);
      final dir = await _audioDir(reciterId);
      final firstFile = File('${dir.path}/${offset + 1}.mp3');
      if (!await firstFile.exists()) toRemove.add(key);
    }
    if (toRemove.isNotEmpty) {
      _downloaded.removeAll(toRemove);
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setStringList(
          'downloaded_audio_surahs', _downloaded.toList());
    }
    notifyListeners();
  }

  Future<Directory> _audioDir(String reciterId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio/$reciterId');
    await dir.create(recursive: true);
    return dir;
  }

  /// Returns the local file path if it exists, otherwise null.
  Future<String?> localFilePath(String reciterId, int absoluteVerse) async {
    final dir = await _audioDir(reciterId);
    final file = File('${dir.path}/$absoluteVerse.mp3');
    return await file.exists() ? file.path : null;
  }

  Future<void> downloadSurah({
    required String reciterId,
    required int surahNumber,
  }) async {
    final key = '$reciterId/$surahNumber';
    if (_downloaded.contains(key) || _progress.containsKey(key)) return;

    final surah = kSurahs.firstWhere((s) => s.number == surahNumber);
    final offset = surahVerseOffset(surahNumber);
    final totalVerses = surah.verses;

    _cancelled[key] = false;
    _progress[key] = 0.0;
    notifyListeners();

    final dir = await _audioDir(reciterId);
    int completed = 0;

    for (int i = 0; i < totalVerses; i++) {
      if (_cancelled[key] == true) {
        _progress.remove(key);
        _cancelled.remove(key);
        notifyListeners();
        return;
      }

      final absoluteVerse = offset + i + 1;
      final file = File('${dir.path}/$absoluteVerse.mp3');

      if (!await file.exists()) {
        final url =
            '${AppConfig.audioCdnBaseUrl}/128/$reciterId/$absoluteVerse.mp3';
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          }
        } catch (_) {
          // Skip on error — verse stays missing, playback falls back to stream
        }
      }

      completed++;
      _progress[key] = completed / totalVerses;
      notifyListeners();
    }

    _progress.remove(key);
    _cancelled.remove(key);
    _downloaded.add(key);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'downloaded_audio_surahs', _downloaded.toList());
  }

  Future<void> cancelDownload(String reciterId, int surahNumber) async {
    _cancelled['$reciterId/$surahNumber'] = true;
  }

  Future<void> deleteSurah({
    required String reciterId,
    required int surahNumber,
  }) async {
    final key = '$reciterId/$surahNumber';
    final surah = kSurahs.firstWhere((s) => s.number == surahNumber);
    final offset = surahVerseOffset(surahNumber);
    final dir = await _audioDir(reciterId);

    for (int i = 0; i < surah.verses; i++) {
      final file = File('${dir.path}/${offset + i + 1}.mp3');
      if (await file.exists()) await file.delete();
    }

    _downloaded.remove(key);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'downloaded_audio_surahs', _downloaded.toList());
  }
}
