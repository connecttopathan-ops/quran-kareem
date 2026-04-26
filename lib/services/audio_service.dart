import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/quran_data.dart';
import 'audio_handler.dart';
import 'audio_download_service.dart';

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

/// Non-Arabic audio language options. Arabic uses the [Reciter] list above.
class AudioLanguageOption {
  final String langCode;
  final String displayName;
  final String editionId;
  final int bitrate;
  final String reciterName;

  const AudioLanguageOption({
    required this.langCode,
    required this.displayName,
    required this.editionId,
    required this.bitrate,
    required this.reciterName,
  });

  static const List<AudioLanguageOption> nonArabic = [
    AudioLanguageOption(langCode: 'en', displayName: 'English', editionId: 'en.walk',                      bitrate: 192, reciterName: 'Ibrahim Walk'),
    AudioLanguageOption(langCode: 'ur', displayName: 'Urdu',    editionId: 'ur.khan',                      bitrate: 64,  reciterName: 'Shamshad Ali Khan'),
    AudioLanguageOption(langCode: 'fr', displayName: 'French',  editionId: 'fr.leclerc',                   bitrate: 128, reciterName: 'Youssouf Leclerc'),
    AudioLanguageOption(langCode: 'fa', displayName: 'Persian', editionId: 'fa.hedayatfarfooladvand',       bitrate: 40,  reciterName: 'Fooladvand'),
  ];

  static AudioLanguageOption? byLangCode(String code) =>
      nonArabic.where((o) => o.langCode == code).firstOrNull;
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

  static const _nowPlayingChannel =
      MethodChannel('co.getquran.app/nowplaying');

  String _reciterId = 'ar.alafasy';
  String _audioLanguage = 'ar'; // 'ar' | 'en' | 'ur' | 'fr' | 'fa'
  NowPlaying? _nowPlaying;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;
  double _playbackSpeed = 1.0;
  Uri? _artworkUri;

  // Held explicitly to prevent garbage collection cancelling the subscriptions.
  late final StreamSubscription _playbackStateSub;
  late final StreamSubscription _commandSub;
  late final StreamSubscription _currentIndexSub;

  String get reciterId => _reciterId;
  Reciter get reciter => Reciter.byId(_reciterId);
  String get audioLanguage => _audioLanguage;

  /// Display name of the currently active reciter / reader.
  String get currentReciterName {
    if (_audioLanguage == 'ar') return reciter.name;
    return AudioLanguageOption.byLangCode(_audioLanguage)?.reciterName ?? '';
  }

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
        // Keep lock screen playback rate in sync with actual play/pause state.
        if (_nowPlaying != null) _updateNativeNowPlaying(_nowPlaying!, playing: playing);
      }
    });
    _commandSub = _handler.commands.listen(_handleCommand);

    // Track which verse just_audio is playing natively within the playlist.
    _currentIndexSub = _handler.player.currentIndexStream.listen((index) {
      if (index == null || _nowPlaying == null) return;
      final newVerse = index + 1; // playlist is 0-based, verses are 1-based
      if (_nowPlaying!.verseNumber != newVerse) {
        _nowPlaying = _nowPlaying!.copyWith(verseNumber: newVerse);
        notifyListeners();
        if (Platform.isIOS) _updateNativeNowPlaying(_nowPlaying!);
      }
    });

    // Handle remote commands sent back from the native Now Playing plugin
    // (lock screen play/pause/next/previous buttons).
    _nowPlayingChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          await _handler.play();
          break;
        case 'pause':
          await _handler.pause();
          break;
        case 'togglePlayPause':
          await togglePlayPause();
          break;
        case 'next':
          await nextSurah();
          break;
        case 'previous':
          await previousSurah();
          break;
      }
    });
  }

  Future<void> _handleCommand(String cmd) async {
    print('[QuranService] _handleCommand cmd=$cmd nowPlaying=${_nowPlaying?.surahNumber}:${_nowPlaying?.verseNumber}');
    switch (cmd) {
      case 'autoNext':
        // Entire surah playlist finished — advance to the next surah.
        await nextSurah();
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

  /// Pushes now-playing metadata to MPNowPlayingInfoCenter via the native plugin.
  /// iOS only — the channel does not exist on Android.
  void _updateNativeNowPlaying(NowPlaying np, {bool playing = true}) {
    if (!Platform.isIOS) return;
    final duration = _handler.player.duration;
    print('[QuranService] _updateNativeNowPlaying title=${np.surahName} verse=${np.verseNumber} playing=$playing');
    _nowPlayingChannel.invokeMethod('setNowPlaying', {
      'title': np.surahName,
      'artist': 'Verse ${np.verseNumber} of ${np.totalVerses}',
      'album': 'The Holy Quran',
      if (duration != null) 'duration': duration.inMilliseconds / 1000.0,
      'position': _handler.player.position.inMilliseconds / 1000.0,
      'playing': playing,
    }).then((_) {
      print('[QuranService] _updateNativeNowPlaying channel call succeeded');
    }).catchError((e) {
      print('[QuranService] _updateNativeNowPlaying channel error: $e');
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _reciterId = p.getString('reciterId') ?? 'ar.alafasy';
    _audioLanguage = p.getString('audioLanguage') ?? 'ar';
    _playbackSpeed = p.getDouble('playbackSpeed') ?? 1.0;
    notifyListeners();
  }

  Future<String> _verseUrl(int absoluteVerse) async {
    if (_audioLanguage == 'ar') {
      final local = await AudioDownloadService()
          .localFilePath(_reciterId, absoluteVerse);
      if (local != null) return 'file://$local';
      return '${AppConfig.audioCdnBaseUrl}/128/$_reciterId/$absoluteVerse.mp3';
    }
    final opt = AudioLanguageOption.byLangCode(_audioLanguage);
    if (opt == null) {
      return '${AppConfig.audioCdnBaseUrl}/128/$_reciterId/$absoluteVerse.mp3';
    }
    return '${AppConfig.audioCdnBaseUrl}/${opt.bitrate}/${opt.editionId}/$absoluteVerse.mp3';
  }

  MediaItem _makeMediaItem(NowPlaying np) => MediaItem(
    id: 'verse-${np.surahNumber}-${np.verseNumber}',
    title: np.surahName,
    artist: 'Verse ${np.verseNumber} of ${np.totalVerses}',
    album: 'The Holy Quran',
    artUri: _artworkUri,
    extras: {'surahNumber': np.surahNumber, 'verseNumber': np.verseNumber},
  );

  /// Loads the entire surah as a gapless playlist starting at [verseNumber].
  /// just_audio handles all verse-to-verse transitions natively — no Dart
  /// code runs between verses, so background audio is uninterrupted.
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
      // Resolve all verse URLs for the surah in parallel.
      final urls = await Future.wait([
        for (int v = 1; v <= totalVerses; v++) _verseUrl(offset + v),
      ]);
      final items = [
        for (int v = 1; v <= totalVerses; v++)
          _makeMediaItem(_nowPlaying!.copyWith(verseNumber: v)),
      ];
      await _handler.playPlaylist(urls, items, verseNumber - 1);
      await _handler.player.setSpeed(_playbackSpeed);
      if (Platform.isIOS) _updateNativeNowPlaying(_nowPlaying!);
    } catch (e) {
      print('[QuranService] playVerse error: $e');
      _isLoading = false;
      _isPlaying = false;
      _error = 'Failed to play audio';
      notifyListeners();
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
      // Seek to start of the next playlist item (0-based index = verseNumber).
      await _handler.player.seek(Duration.zero, index: _nowPlaying!.verseNumber);
    }
  }

  Future<void> previousVerse() async {
    if (_nowPlaying == null) return;
    if (_nowPlaying!.verseNumber > 1) {
      // Seek to start of the previous playlist item (0-based index = verseNumber - 2).
      await _handler.player.seek(Duration.zero, index: _nowPlaying!.verseNumber - 2);
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
      await playVerse(
        surahNumber: _nowPlaying!.surahNumber,
        surahName: _nowPlaying!.surahName,
        verseNumber: _nowPlaying!.verseNumber,
        totalVerses: _nowPlaying!.totalVerses,
      );
    }
    notifyListeners();
  }

  Future<void> setAudioLanguage(String langCode) async {
    _audioLanguage = langCode;
    final p = await SharedPreferences.getInstance();
    await p.setString('audioLanguage', langCode);
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
    await _handler.player.setSpeed(speed);
    notifyListeners();
  }

  bool isVersePlayingNow(int surah, int verse) =>
      _isPlaying && _nowPlaying?.surahNumber == surah && _nowPlaying?.verseNumber == verse;

  @override
  void dispose() {
    _playbackStateSub.cancel();
    _commandSub.cancel();
    _currentIndexSub.cancel();
    _handler.dispose();
    super.dispose();
  }
}
