import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
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
  ConcatenatingAudioSource? _playlist;
  int _playlistBaseVerse = 1;

  String _reciterId = 'ar.alafasy';
  NowPlaying? _nowPlaying;
  bool _isPlaying = false, _isLoading = false;
  String? _error;
  double _playbackSpeed = 1.0;

  final _surahCompleteController = StreamController<int>.broadcast();
  Stream<int> get onSurahComplete => _surahCompleteController.stream;

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

    // Track current playlist index to update nowPlaying verse and preload ahead
    _player.currentIndexStream.listen((index) async {
      if (index == null || _nowPlaying == null) return;
      final newVerse = _playlistBaseVerse + index;
      if (_nowPlaying!.verseNumber != newVerse) {
        _nowPlaying = _nowPlaying!.copyWith(verseNumber: newVerse);
        notifyListeners();
      }
      await _maybeExtendPlaylist(index);
    });

    _player.playerStateStream.listen((state) {
      final playing = state.playing &&
          state.processingState != ProcessingState.completed;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
      if (state.processingState == ProcessingState.completed) {
        _handlePlaylistComplete();
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
    return AudioSource.uri(
      Uri.parse(_audioUrl(absoluteVerse)),
      tag: MediaItem(
        id: 'ayah_$absoluteVerse',
        title: '$surahName — Ayah $verseNumber',
        artist: 'Get Quran',
        album: 'Holy Quran · $surahName',
        displayTitle: '$surahName — Ayah $verseNumber',
        displaySubtitle: 'Get Quran',
      ),
    );
  }

  Future<void> _maybeExtendPlaylist(int currentIndex) async {
    if (_playlist == null || _nowPlaying == null) return;
    const preloadAhead = 2;
    final lastPlaylistVerse = _playlistBaseVerse + _playlist!.length - 1;
    final targetLastVerse = min(
      _playlistBaseVerse + currentIndex + preloadAhead,
      _nowPlaying!.totalVerses,
    );
    if (lastPlaylistVerse < targetLastVerse) {
      for (int v = lastPlaylistVerse + 1; v <= targetLastVerse; v++) {
        final abs = _nowPlaying!.surahVerseOffset + v;
        await _playlist!.add(_buildSource(abs, _nowPlaying!.surahNumber, v, _nowPlaying!.surahName));
      }
    }
  }

  void _handlePlaylistComplete() {
    if (_nowPlaying == null) return;
    _isPlaying = false;
    if (_nowPlaying!.surahNumber < 114) {
      _surahCompleteController.add(_nowPlaying!.surahNumber + 1);
    }
    notifyListeners();
  }

  Future<void> playVerse({
    required int surahNumber,
    required String surahName,
    required int verseNumber,
    required int totalVerses,
  }) async {
    // Request notification permission for Android 13+ before first playback
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    _error = null;
    final offset = surahVerseOffset(surahNumber);
    _playlistBaseVerse = verseNumber;
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

      // Build initial playlist: current + next 2 ayahs (or fewer near end)
      const initialLoad = 3;
      final endVerse = min(verseNumber + initialLoad - 1, totalVerses);
      final children = <AudioSource>[];
      for (int v = verseNumber; v <= endVerse; v++) {
        children.add(_buildSource(offset + v, surahNumber, v, surahName));
      }
      _playlist = ConcatenatingAudioSource(children: children);

      await _player.setAudioSource(_playlist!, initialIndex: 0);
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
    _playlist = null;
    notifyListeners();
  }

  Future<void> nextVerse() async {
    if (_nowPlaying == null) return;
    final currentVerse = _nowPlaying!.verseNumber;
    if (currentVerse >= _nowPlaying!.totalVerses) return;
    final nextVerse = currentVerse + 1;
    final nextIndex = nextVerse - _playlistBaseVerse;
    if (_playlist != null && nextIndex >= 0 && nextIndex < _playlist!.length) {
      await _player.seek(Duration.zero, index: nextIndex);
    } else {
      await playVerse(
        surahNumber: _nowPlaying!.surahNumber,
        surahName: _nowPlaying!.surahName,
        verseNumber: nextVerse,
        totalVerses: _nowPlaying!.totalVerses,
      );
    }
  }

  Future<void> previousVerse() async {
    if (_nowPlaying == null) return;
    final currentVerse = _nowPlaying!.verseNumber;
    if (currentVerse <= 1) return;
    final prevVerse = currentVerse - 1;
    final prevIndex = prevVerse - _playlistBaseVerse;
    if (_playlist != null && prevIndex >= 0 && prevIndex < _playlist!.length) {
      await _player.seek(Duration.zero, index: prevIndex);
    } else {
      await playVerse(
        surahNumber: _nowPlaying!.surahNumber,
        surahName: _nowPlaying!.surahName,
        verseNumber: prevVerse,
        totalVerses: _nowPlaying!.totalVerses,
      );
    }
  }

  Future<void> setReciter(String id) async {
    _reciterId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('reciterId', id);
    if (_nowPlaying != null) {
      await playVerse(
        surahNumber: _nowPlaying!.surahNumber,
        surahName: _nowPlaying!.surahName,
        verseNumber: _nowPlaying!.verseNumber,
        totalVerses: _nowPlaying!.totalVerses,
      );
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
    _surahCompleteController.close();
    _player.dispose();
    super.dispose();
  }
}
