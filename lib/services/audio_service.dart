import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';

class Reciter {
  final String id, name, arabicName, style;
  const Reciter(this.id, this.name, this.arabicName, this.style);
  static const List<Reciter> all = [
    Reciter('ar.alafasy',           'Mishary Rashid Alafasy',    'مشاري راشد العفاسي',   'Murattal'),
    Reciter('ar.abdurrahmaansudais','Abdul Rahman Al-Sudais',    'عبد الرحمن السديس',    'Murattal'),
    Reciter('ar.abdulbasitmurattal','Abdul Basit (Murattal)',     'عبد الباسط عبد الصمد', 'Murattal'),
    Reciter('ar.abdulbasitmujawwad','Abdul Basit (Mujawwad)',     'عبد الباسط عبد الصمد', 'Mujawwad'),
    Reciter('ar.husary',            'Mahmoud Khalil Al-Husary',  'محمود خليل الحصري',    'Murattal'),
    Reciter('ar.minshawi',          'Mohamed Siddiq Al-Minshawi','محمد صديق المنشاوي',   'Murattal'),
  ];
  static Reciter byId(String id) => all.firstWhere((r) => r.id == id, orElse: () => all[0]);
}

class NowPlaying {
  final int surahNumber, verseNumber, totalVerses, surahVerseOffset;
  final String surahName;
  const NowPlaying({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.totalVerses,
    required this.surahVerseOffset,
  });
  NowPlaying copyWith({int? verseNumber}) => NowPlaying(
    surahNumber: surahNumber,
    surahName: surahName,
    verseNumber: verseNumber ?? this.verseNumber,
    totalVerses: totalVerses,
    surahVerseOffset: surahVerseOffset,
  );

  int get absoluteVerseNumber => surahVerseOffset + verseNumber;
}

/// Compute the cumulative verse offset before [surahNumber].
int surahVerseOffset(int surahNumber) {
  int offset = 0;
  for (final s in kSurahs) {
    if (s.number >= surahNumber) break;
    offset += s.verses;
  }
  return offset;
}

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
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

  AudioService() {
    _loadPrefs();
    _player.playerStateStream.listen((state) {
      final playing = state.playing &&
          state.processingState != ProcessingState.completed;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
      if (state.processingState == ProcessingState.completed) {
        _autoNextVerse();
      }
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _reciterId = p.getString('reciterId') ?? 'ar.alafasy';
    _playbackSpeed = p.getDouble('playbackSpeed') ?? 1.0;
    notifyListeners();
  }

  String _audioUrl(int absoluteVerse) =>
      'https://cdn.islamic.network/quran/audio/128/$_reciterId/$absoluteVerse.mp3';

  AudioSource _buildSource(int absoluteVerse, int surahNumber, int verseNumber, String surahName) {
    return AudioSource.uri(Uri.parse(_audioUrl(absoluteVerse)));
  }

  Future<void> playVerse({
    required int surahNumber,
    required String surahName,
    required int verseNumber,
    required int totalVerses,
  }) async {
    _error = null;
    final offset = surahVerseOffset(surahNumber);
    _nowPlaying = NowPlaying(
      surahNumber: surahNumber,
      surahName: surahName,
      verseNumber: verseNumber,
      totalVerses: totalVerses,
      surahVerseOffset: offset,
    );
    _isLoading = true;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setAudioSource(_buildSource(
        _nowPlaying!.absoluteVerseNumber,
        surahNumber,
        verseNumber,
        surahName,
      ));
      await _player.setSpeed(_playbackSpeed);
      await _player.play();
      _isLoading = false;
      _isPlaying = true;
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      _error = 'Failed to play audio';
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_nowPlaying == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _nowPlaying = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> _autoNextVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber < _nowPlaying!.totalVerses) {
      final next = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber + 1);
      _nowPlaying = next;
      notifyListeners();
      try {
        await _player.setAudioSource(_buildSource(
          _nowPlaying!.absoluteVerseNumber,
          _nowPlaying!.surahNumber,
          _nowPlaying!.verseNumber,
          _nowPlaying!.surahName,
        ));
        await _player.play();
      } catch (_) {}
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> nextVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber < _nowPlaying!.totalVerses) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber + 1);
      notifyListeners();
      try {
        await _player.stop();
        await _player.setAudioSource(_buildSource(
          _nowPlaying!.absoluteVerseNumber,
          _nowPlaying!.surahNumber,
          _nowPlaying!.verseNumber,
          _nowPlaying!.surahName,
        ));
        await _player.play();
      } catch (_) {}
    }
  }

  Future<void> previousVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber > 1) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber - 1);
      notifyListeners();
      try {
        await _player.stop();
        await _player.setAudioSource(_buildSource(
          _nowPlaying!.absoluteVerseNumber,
          _nowPlaying!.surahNumber,
          _nowPlaying!.verseNumber,
          _nowPlaying!.surahName,
        ));
        await _player.play();
      } catch (_) {}
    }
  }

  Future<void> setReciter(String id) async {
    _reciterId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('reciterId', id);
    if (_nowPlaying != null) {
      try {
        await _player.stop();
        await _player.setAudioSource(_buildSource(
          _nowPlaying!.absoluteVerseNumber,
          _nowPlaying!.surahNumber,
          _nowPlaying!.verseNumber,
          _nowPlaying!.surahName,
        ));
        await _player.play();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('playbackSpeed', speed);
    await _player.setSpeed(speed);
    notifyListeners();
  }

  bool isVersePlayingNow(int surah, int verse) =>
      _isPlaying && _nowPlaying?.surahNumber == surah && _nowPlaying?.verseNumber == verse;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
