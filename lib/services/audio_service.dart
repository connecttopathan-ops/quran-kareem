import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
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
    _playbackStateSub = _handler.playbackState.listen((state) {
      final playing = state.playing;
      final loading = state.processingState == AudioProcessingState.loading ||
          state.processingState == AudioProcessingState.buffering;
      if (_isPlaying != playing || _isLoading != loading) {
        _isPlaying = playing;
        _isLoading = loading;
        notifyListeners();
      }
    });
    _commandSub = _handler.commands.listen(_handleCommand);
  }

  Future<void> _handleCommand(String cmd) async {
    switch (cmd) {
      case 'autoNext':
        await _onAutoNext();
        break;
      case 'completed':
        // Last item in queue finished (end of Quran or no next preloaded).
        _isPlaying = false;
        notifyListeners();
        break;
      case 'nextSurah':
        await nextSurah();
        break;
      case 'prevSurah':
        await previousSurah();
        break;
    }
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
    artist: 'Get Quran · Verse ${np.verseNumber}/${np.totalVerses}',
    album: 'The Holy Quran',
    extras: {'surahNumber': np.surahNumber, 'verseNumber': np.verseNumber},
  );

  /// Returns the absolute verse number that comes after [np], crossing surah
  /// boundaries. Returns null if [np] is the last verse of the Quran.
  int? _nextAbsoluteVerseFor(NowPlaying np) {
    if (np.verseNumber < np.totalVerses) {
      return np.absoluteVerseNumber + 1;
    }
    if (np.surahNumber < 114) {
      return surahVerseOffset(np.surahNumber + 1) + 1;
    }
    return null; // end of Quran
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
      final nextAbs = _nextAbsoluteVerseFor(_nowPlaying!);
      await _handler.playFromUrl(
        _verseUrl(_nowPlaying!.absoluteVerseNumber),
        _makeMediaItem(_nowPlaying!),
        nextUrl: nextAbs != null ? _verseUrl(nextAbs) : null,
      );
      await _handler.player.setSpeed(_playbackSpeed);
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      _error = 'Failed to play audio';
      notifyListeners();
    }
  }

  /// Called when just_audio gaplessly advances to the next queued track.
  /// Updates state and enqueues the track after the one now playing.
  Future<void> _onAutoNext() async {
    if (_nowPlaying == null) return;
    final prev = _nowPlaying!;

    // Compute new NowPlaying — may cross a surah boundary.
    final NowPlaying next;
    if (prev.verseNumber < prev.totalVerses) {
      next = prev.copyWith(verseNumber: prev.verseNumber + 1);
    } else if (prev.surahNumber < 114) {
      final nextSurahNum = prev.surahNumber + 1;
      final s = kSurahs[nextSurahNum - 1];
      next = NowPlaying(
        surahNumber: nextSurahNum,
        surahName: s.nameTransliteration,
        verseNumber: 1,
        totalVerses: s.verses,
        surahVerseOffset: surahVerseOffset(nextSurahNum),
      );
    } else {
      // End of Quran — queue will emit 'completed' when done.
      return;
    }

    _nowPlaying = next;
    // Update the lock screen / notification media item.
    _handler.mediaItem.add(_makeMediaItem(next));
    notifyListeners();

    // Enqueue the verse after the one now playing so the next transition
    // is also gapless.
    final nextAbs = _nextAbsoluteVerseFor(next);
    if (nextAbs != null) {
      await _handler.enqueueNext(_verseUrl(nextAbs));
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
        final nextAbs = _nextAbsoluteVerseFor(_nowPlaying!);
        await _handler.playFromUrl(
          _verseUrl(_nowPlaying!.absoluteVerseNumber),
          _makeMediaItem(_nowPlaying!),
          nextUrl: nextAbs != null ? _verseUrl(nextAbs) : null,
        );
      } catch (_) {}
    }
  }

  Future<void> previousVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber > 1) {
      _nowPlaying = _nowPlaying!.copyWith(verseNumber: _nowPlaying!.verseNumber - 1);
      notifyListeners();
      try {
        final nextAbs = _nextAbsoluteVerseFor(_nowPlaying!);
        await _handler.playFromUrl(
          _verseUrl(_nowPlaying!.absoluteVerseNumber),
          _makeMediaItem(_nowPlaying!),
          nextUrl: nextAbs != null ? _verseUrl(nextAbs) : null,
        );
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
        final nextAbs = _nextAbsoluteVerseFor(_nowPlaying!);
        await _handler.playFromUrl(
          _verseUrl(_nowPlaying!.absoluteVerseNumber),
          _makeMediaItem(_nowPlaying!),
          nextUrl: nextAbs != null ? _verseUrl(nextAbs) : null,
        );
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
