import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
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
    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });
    _player.bufferedPositionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(bufferedPosition: pos));
    });
    // Propagate duration to MediaItem so iOS shows the Now Playing widget
    // on the lock screen and Control Center with a progress bar.
    _player.durationStream.listen((duration) {
      if (duration != null) {
        final current = mediaItem.value;
        if (current != null && current.duration != duration) {
          mediaItem.add(current.copyWith(duration: duration));
        }
      }
    });
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

    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[state.processingState]!;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        state.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: processingState,
      playing: state.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
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
    mediaItem.add(item);
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

  @override
  Future<void> play() async {
    _intentionalStop = false;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    _intentionalStop = true;
    _watchdogTimer?.cancel();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _intentionalStop = true;
    _watchdogTimer?.cancel();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => _commandController.add('nextSurah');

  @override
  Future<void> skipToPrevious() async => _commandController.add('prevSurah');

  @override
  Future<void> onTaskRemoved() async => stop();

  void dispose() {
    _watchdogTimer?.cancel();
    _commandController.close();
    _player.dispose();
  }
}
