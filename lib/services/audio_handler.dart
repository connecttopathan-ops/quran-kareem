import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class QuranAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  static bool _backgroundInitialized = false;
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

  // iOS 26: setUpPlayerItemStatusObservation Swift continuation leaks.
  // processingState.completed may not fire; playing state can churn during init.
  //
  // Three detection layers:
  //   1. processingState.completed (fast, may not fire on iOS 26)
  //   2. playing true→false, guarded by 1s minimum play time
  //      (prevents false trigger from iOS 26 init state churn)
  //   3. Timer.periodic watchdog: position stale for 800ms = track ended
  bool _completionFired = false;
  bool _intentionalStop = false;
  bool _wasPlaying = false;
  DateTime? _playStartTime; // Set when playing first becomes true after a load

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
      if (posMs < 200) return; // Skip silence at track start

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
      // Track when playback actually began (for layer 2 guard)
      _playStartTime = DateTime.now();
    }

    // Layer 2: playing→stopped, but only after ≥1s of actual playback.
    // This prevents iOS 26 init state churn (playing=true/false within the
    // first ~200ms after play() is called) from firing a spurious autoNext.
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

  Future<void> playFromUrl(String url, MediaItem item) async {
    print('[QuranAudio] playFromUrl url=$url');
    _intentionalStop = true;
    _completionFired = false;
    _wasPlaying = false;
    _playStartTime = null;
    _watchdogTimer?.cancel();
    _watchdogLastMs = null;
    _watchdogStaleTicks = 0;
    // Initialise JustAudioBackground on first play so the foreground service
    // only starts when the user explicitly presses play (Play Store policy).
    if (!_backgroundInitialized) {
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
    try {
      // Use setAudioSource with tag so just_audio_background populates
      // MPNowPlayingInfoCenter for the iOS lock screen widget.
      // Short timeout: iOS 26 continuation leaks but AVPlayer still loads.
      await _player
          .setAudioSource(AudioSource.uri(Uri.parse(url), tag: item))
          .timeout(const Duration(milliseconds: 300));
      print('[QuranAudio] setAudioSource done');
    } catch (e) {
      print('[QuranAudio] setAudioSource timeout (iOS 26 expected) — playing anyway');
    }
    try {
      await _player.play().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[QuranAudio] play() error/timeout: $e');
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
