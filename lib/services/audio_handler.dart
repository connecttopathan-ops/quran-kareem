import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class QuranAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  static bool _backgroundInitialized = false;
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

  // End-of-surah detection layers.
  // With a ConcatenatingAudioSource playlist, just_audio handles verse-to-verse
  // transitions natively. These layers only fire when the entire surah ends.
  //
  //   1. processingState.completed (fast, may not fire on iOS 26)
  //   2. playing true→false, guarded by 1s minimum play time
  //   3. Timer.periodic watchdog: position stale for 800ms
  bool _completionFired = false;
  bool _intentionalStop = false;
  bool _wasPlaying = false;
  DateTime? _playStartTime;

  // Layer 3 watchdog
  Timer? _watchdogTimer;
  int? _watchdogLastMs;
  int _watchdogStaleTicks = 0;
  static const int _kStaleTicks = 4;    // 4 × 200 ms = 800 ms stale
  static const int _kStaleDelta = 50;   // < 50 ms movement = stale

  Stream<String> get commands => _commandController.stream;
  AudioPlayer get player => _player;

  QuranAudioHandler() {
    _player.playerStateStream.listen(_syncPlaybackState);
    // Layer 1
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingState=$state');
      if (state == ProcessingState.completed) {
        _fireAutoNext('processingState.completed');
      }
    });
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogLastMs = null;
    _watchdogStaleTicks = 0;
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_intentionalStop || !_wasPlaying) {
        _watchdogLastMs = null;
        _watchdogStaleTicks = 0;
        return;
      }
      final posMs = _player.position.inMilliseconds;
      if (posMs < 200) return;

      final lastMs = _watchdogLastMs;
      final delta = lastMs == null ? 9999 : (posMs - lastMs).abs();
      if (delta < _kStaleDelta) {
        _watchdogStaleTicks++;
        print('[QuranAudio] watchdog stale tick=$_watchdogStaleTicks pos=${posMs}ms');
        if (_watchdogStaleTicks >= _kStaleTicks) {
          t.cancel();
          _watchdogLastMs = null;
          _watchdogStaleTicks = 0;
          _fireAutoNext('position-stale');
        }
      } else {
        _watchdogStaleTicks = 0;
        _watchdogLastMs = posMs;
      }
    });
  }

  void _fireAutoNext(String source) {
    if (_completionFired || _intentionalStop) return;
    _completionFired = true;
    print('[QuranAudio] >> autoNext via $source');
    _commandController.add('autoNext');
  }

  void _syncPlaybackState(PlayerState state) {
    print('[QuranAudio] playerState playing=${state.playing} proc=${state.processingState}');

    if (!_wasPlaying && state.playing) {
      _playStartTime = DateTime.now();
    }

    // Layer 2: playing→stopped, guarded by ≥1s of actual playback.
    if (_wasPlaying && !state.playing && !_intentionalStop) {
      final elapsed = _playStartTime != null
          ? DateTime.now().difference(_playStartTime!)
          : Duration.zero;
      if (elapsed >= const Duration(milliseconds: 1000)) {
        _fireAutoNext('playing→stopped');
      } else {
        print('[QuranAudio] playing→stopped ignored (elapsed=${elapsed.inMilliseconds}ms < 1000ms)');
      }
    }

    _wasPlaying = state.playing;
  }

  static Future<void> initBackground() async {
    if (_backgroundInitialized) return;
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'co.getquran.app.audio',
        androidNotificationChannelName: 'Quran Audio',
        preloadArtwork: true,
      );
      _backgroundInitialized = true;
      print('[QuranAudio] JustAudioBackground.init succeeded');
    } catch (e) {
      print('[QuranAudio] JustAudioBackground.init FAILED: $e');
    }
  }

  Future<void> _initBackground() => QuranAudioHandler.initBackground();

  /// Loads [urls] as a gapless playlist and starts at [startIndex].
  /// just_audio handles all verse-to-verse transitions natively without
  /// any Dart code running between them — safe for background playback.
  /// [autoNext] only fires when the entire playlist (surah) finishes.
  Future<void> playPlaylist(
      List<String> urls, List<MediaItem> items, int startIndex) async {
    print('[QuranAudio] playPlaylist verses=${urls.length} startIndex=$startIndex');
    _intentionalStop = true;
    _completionFired = false;
    _wasPlaying = false;
    _playStartTime = null;
    _watchdogTimer?.cancel();
    _watchdogLastMs = null;
    _watchdogStaleTicks = 0;

    await _initBackground();

    final playlist = ConcatenatingAudioSource(
      children: [
        for (int i = 0; i < urls.length; i++)
          AudioSource.uri(Uri.parse(urls[i]), tag: items[i]),
      ],
    );

    try {
      if (Platform.isIOS) {
        // iOS 26: Swift continuation leaks — cap wait, AVPlayer still loads.
        await _player
            .setAudioSource(playlist,
                initialIndex: startIndex, initialPosition: Duration.zero)
            .timeout(const Duration(milliseconds: 500));
      } else {
        await _player.setAudioSource(playlist,
            initialIndex: startIndex, initialPosition: Duration.zero);
      }
      print('[QuranAudio] setAudioSource playlist done');
    } catch (e) {
      print('[QuranAudio] setAudioSource playlist error: $e — verifying');
      // iOS 26: the Future may never resolve even though AVPlayer loaded.
      // Give the engine a brief grace period, then retry once if still idle.
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (_player.processingState == ProcessingState.idle) {
          print('[QuranAudio] state still idle — retrying setAudioSource');
          try {
            await _player
                .setAudioSource(playlist,
                    initialIndex: startIndex, initialPosition: Duration.zero)
                .timeout(const Duration(seconds: 2));
          } catch (e2) {
            print('[QuranAudio] retry setAudioSource also failed: $e2');
          }
        }
      }
    }

    try {
      // iOS 26: Swift continuation leaks cause play() to never resolve —
      // cap the wait. On Android the timeout caused an FGS ANR because
      // just_audio_background needs the play() Future to complete in order
      // to call startForeground(); cancelling it early left the service in
      // an invalid state → Android killed the process.
      if (Platform.isIOS) {
        await _player.play().timeout(const Duration(seconds: 5));
      } else {
        await _player.play();
      }
    } catch (e) {
      print('[QuranAudio] play() error/timeout: $e — verifying playback');
      // If the player is actually playing, the timeout was a false alarm.
      // If still not playing after a beat, retry play() once.
      if (Platform.isIOS && !_player.playing) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!_player.playing) {
          try {
            await _player.play().timeout(const Duration(seconds: 3));
          } catch (e2) {
            print('[QuranAudio] retry play() also failed: $e2');
          }
        }
      }
    }
    _intentionalStop = false;
    _startWatchdog();
    print('[QuranAudio] watchdog started');
  }

  Future<void> play() async {
    _intentionalStop = false;
    await _player.play();
  }

  Future<void> pause() async {
    _intentionalStop = true;
    _watchdogTimer?.cancel();
    await _player.pause();
  }

  Future<void> stop() async {
    _intentionalStop = true;
    _watchdogTimer?.cancel();
    await _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipToNext() async => _commandController.add('nextSurah');
  Future<void> skipToPrevious() async => _commandController.add('prevSurah');

  void dispose() {
    _watchdogTimer?.cancel();
    _commandController.close();
    _player.dispose();
  }
}
