import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import 'audio_handler.dart';

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
  static Reciter byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => all[0]);
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

/// Compute cumulative verse offset before [surahNumber].
int surahVerseOffset(int surahNumber) {
  int offset = 0;
  for (final s in kSurahs) {
    if (s.number >= surahNumber) break;
    offset += s.verses;
  }
  return offset;
}

class AudioService extends ChangeNotifier {
  final QuranAudioHandler _handler;

  String _reciterId = 'ar.alafasy';
  NowPlaying? _nowPlaying;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;
  double _playbackSpeed = 1.0;
  Uri? _artworkUri;

  // Held explicitly to prevent garbage collection cancelling the subscriptions.
  late final StreamSubscription _playbackStateSub;
  late final StreamSubscription _commandSub;

  String get reciterId => _reciterId;
  Reciter get reciter => Reciter.byId(_reciterId);
  NowPlaying? get nowPlaying => _nowPlaying;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get playbackSpeed => _playbackSpeed;
  bool get hasAudio => _nowPlaying != null;

  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;

  AudioService(this._handler) {
    _loadPrefs();
    _loadArtwork();
    _playbackStateSub = _handler.player.playerStateStream.listen((state) {
      final playing = state.playing;
      final loading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (_isPlaying != playing || _isLoading != loading) {
        _isPlaying = playing;
        _isLoading = loading;
        notifyListeners();
      }
    });
    _commandSub = _handler.commands.listen(_handleCommand);
  }

  Future<void> _handleCommand(String cmd) async {
    print('[QuranService] _handleCommand cmd=$cmd nowPlaying=${_nowPlaying?.surahNumber}:${_nowPlaying?.verseNumber}');
    switch (cmd) {
      case 'autoNext':
        await _autoNextVerse();
        break;
      case 'nextSurah':
        await nextSurah();
        break;
      case 'prevSurah':
        await previousSurah();
        break;
    }
  }

  Future<void> _loadArtwork() async {
    try {
      final data = await rootBundle.load('assets/icon/icon.png');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/quran_artwork.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      _artworkUri = file.uri;
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _reciterId = p.getString('reciterId') ?? 'ar.alafasy';
    _playbackSpeed = p.getDouble('playbackSpeed') ?? 1.0;
    notifyListeners();
  }

  String _verseUrl(int absoluteVerse) =>
      'https://cdn.islamic.network/quran/audio/128/$_reciterId/$absoluteVerse.mp3';

  MediaItem _makeMediaItem(NowPlaying np) => MediaItem(
    id: 'verse-${np.surahNumber}-${np.verseNumber}',
    title: np.surahName,
    artist: 'Verse ${np.verseNumber} of ${np.totalVerses}',
    album: 'The Holy Quran',
    artUri: _artworkUri,
    extras: {'surahNumber': np.surahNumber, 'verseNumber': np.verseNumber},
  );

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
      await _handler.playFromUrl(
          _verseUrl(_nowPlaying!.absoluteVerseNumber), _makeMediaItem(_nowPlaying!));
      await _handler.player.setSpeed(_playbackSpeed);
    } catch (e) {
      print('[QuranService] playVerse error: $e');
      _isLoading = false;
      _isPlaying = false;
      _error = 'Failed to play audio';
      notifyListeners();
    }
  }

  /// Called when the current verse finishes. Advances to the next verse or
  /// next surah without calling stop(), keeping the iOS audio session active.
  Future<void> _autoNextVerse() async {
    print('[QuranService] _autoNextVerse entry nowPlaying=${_nowPlaying?.surahNumber}:${_nowPlaying?.verseNumber}');
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber < _nowPlaying!.totalVerses) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber + 1);
      print('[QuranService] _autoNextVerse advancing to verse ${_nowPlaying!.verseNumber}');
      notifyListeners();
      try {
        await _handler.playFromUrl(
            _verseUrl(_nowPlaying!.absoluteVerseNumber), _makeMediaItem(_nowPlaying!));
      } catch (e) {
        print('[QuranService] _autoNextVerse error: $e');
      }
    } else {
      print('[QuranService] _autoNextVerse end of surah, calling nextSurah');
      await nextSurah();
    }
  }

  Future<void> togglePlayPause() async {
    if (_nowPlaying == null) return;
    if (_isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> stop() async {
    await _handler.stop();
    _nowPlaying = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> nextVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber < _nowPlaying!.totalVerses) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber + 1);
      notifyListeners();
      try {
        await _handler.playFromUrl(
            _verseUrl(_nowPlaying!.absoluteVerseNumber), _makeMediaItem(_nowPlaying!));
      } catch (_) {}
    }
  }

  Future<void> previousVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber > 1) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber - 1);
      notifyListeners();
      try {
        await _handler.playFromUrl(
            _verseUrl(_nowPlaying!.absoluteVerseNumber), _makeMediaItem(_nowPlaying!));
      } catch (_) {}
    }
  }

  Future<void> nextSurah() async {
    if (_nowPlaying == null) return;
    final nextNum = _nowPlaying!.surahNumber + 1;
    if (nextNum > 114) return;
    final s = kSurahs[nextNum - 1];
    await playVerse(
        surahNumber: nextNum,
        surahName: s.nameTransliteration,
        verseNumber: 1,
        totalVerses: s.verses);
  }

  Future<void> previousSurah() async {
    if (_nowPlaying == null) return;
    final prevNum = _nowPlaying!.surahNumber - 1;
    if (prevNum < 1) return;
    final s = kSurahs[prevNum - 1];
    await playVerse(
        surahNumber: prevNum,
        surahName: s.nameTransliteration,
        verseNumber: 1,
        totalVerses: s.verses);
  }

  Future<void> setReciter(String id) async {
    _reciterId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('reciterId', id);
    if (_nowPlaying != null) {
      try {
        await _handler.playFromUrl(
            _verseUrl(_nowPlaying!.absoluteVerseNumber), _makeMediaItem(_nowPlaying!));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('playbackSpeed', speed);
    await _handler.player.setSpeed(speed);
    notifyListeners();
  }

  bool isVersePlayingNow(int surah, int verse) =>
      _isPlaying && _nowPlaying?.surahNumber == surah && _nowPlaying?.verseNumber == verse;

  @override
  void dispose() {
    _playbackStateSub.cancel();
    _commandSub.cancel();
    _handler.dispose();
    super.dispose();
  }
}
