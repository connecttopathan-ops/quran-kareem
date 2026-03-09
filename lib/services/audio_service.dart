import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reciter {
  final String id, name, arabicName, style;
  const Reciter(this.id, this.name, this.arabicName, this.style);
  static const List<Reciter> all = [
    Reciter('ar.alafasy',           'Mishary Rashid Alafasy',    '\u0645\u0634\u0627\u0631\u064a \u0631\u0627\u0634\u062f \u0627\u0644\u0639\u0641\u0627\u0633\u064a',   'Murattal'),
    Reciter('ar.abdurrahmaansudais','Abdul Rahman Al-Sudais',    '\u0639\u0628\u062f \u0627\u0644\u0631\u062d\u0645\u0646 \u0627\u0644\u0633\u062f\u064a\u0633',    'Murattal'),
    Reciter('ar.abdulbasitmurattal','Abdul Basit (Murattal)',     '\u0639\u0628\u062f \u0627\u0644\u0628\u0627\u0633\u0637 \u0639\u0628\u062f \u0627\u0644\u0635\u0645\u062f', 'Murattal'),
    Reciter('ar.abdulbasitmujawwad','Abdul Basit (Mujawwad)',     '\u0639\u0628\u062f \u0627\u0644\u0628\u0627\u0633\u0637 \u0639\u0628\u062f \u0627\u0644\u0635\u0645\u062f', 'Mujawwad'),
    Reciter('ar.husary',            'Mahmoud Khalil Al-Husary',  '\u0645\u062d\u0645\u0648\u062f \u062e\u0644\u064a\u0644 \u0627\u0644\u062d\u0635\u0631\u064a',    'Murattal'),
    Reciter('ar.minshawi',          'Mohamed Siddiq Al-Minshawi','\u0645\u062d\u0645\u062f \u0635\u062f\u064a\u0642 \u0627\u0644\u0645\u0646\u0634\u0627\u0648\u064a',   'Murattal'),
  ];
  static Reciter byId(String id) => all.firstWhere((r) => r.id == id, orElse: () => all[0]);
}

class NowPlaying {
  final int surahNumber, verseNumber, totalVerses;
  final String surahName;
  const NowPlaying({required this.surahNumber, required this.surahName, required this.verseNumber, required this.totalVerses});
  NowPlaying copyWith({int? verseNumber}) => NowPlaying(surahNumber: surahNumber, surahName: surahName, verseNumber: verseNumber ?? this.verseNumber, totalVerses: totalVerses);
}

class AudioService extends ChangeNotifier {
  String _reciterId = 'ar.alafasy';
  NowPlaying? _nowPlaying;
  bool _isPlaying = false, _isLoading = false;
  String? _error;
  double _playbackSpeed = 1.0;

  String get reciterId => _reciterId;
  Reciter get reciter => Reciter.byId(_reciterId);
  NowPlaying? get nowPlaying => _nowPlaying;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get playbackSpeed => _playbackSpeed;
  bool get hasAudio => _nowPlaying != null;

  AudioService() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _reciterId = p.getString('reciterId') ?? 'ar.alafasy';
    _playbackSpeed = p.getDouble('playbackSpeed') ?? 1.0;
    notifyListeners();
  }

  Future<void> playVerse({required int surahNumber, required String surahName, required int verseNumber, required int totalVerses}) async {
    _nowPlaying = NowPlaying(surahNumber: surahNumber, surahName: surahName, verseNumber: verseNumber, totalVerses: totalVerses);
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> togglePlayPause() async { _isPlaying = !_isPlaying; notifyListeners(); }
  Future<void> stop() async { _nowPlaying = null; _isPlaying = false; notifyListeners(); }
  Future<void> nextVerse() async {}
  Future<void> previousVerse() async {}

  Future<void> setReciter(String id) async {
    _reciterId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('reciterId', id);
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('playbackSpeed', speed);
    notifyListeners();
  }

  bool isVersePlayingNow(int surah, int verse) => _isPlaying && _nowPlaying?.surahNumber == surah && _nowPlaying?.verseNumber == verse;
}