import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

  // iOS 26: setUpPlayerItemStatusObservation Swift continuation leaks.
  // processingState.completed may never fire; playing may never go false.
  // Three-layer detection:
  //   1. processingState.completed
  //   2. playing true→false transition
  //   3. Timer.periodic position-staleness watchdog
  bool _completionFired = false;
  bool _intentionalStop = false;
  bool _wasPlaying = false;

  // Watchdog: Timer.periodic polls _player.position directly every 300 ms.
  // Uses millisecond tolerance to avoid microsecond jitter false-negatives.
  Timer? _watchdogTimer;
  int? _watchdogLastMs;
  int _watchdogStaleTicks = 0;
  static const int _kStaleTicks = 5; // 5 × 300 ms = 1.5 s of no movement

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
    // Layer 1: primary completion detection (may not fire on iOS 26).
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingStateStream state=$state');
      if (state == ProcessingState.completed) {
        _fireAutoNext('processingState.completed');
      }
    });
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogLastMs = null;
    _watchdogStaleTicks = 0;
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (_intentionalStop || !_wasPlaying) {
        _watchdogLastMs = null;
        _watchdogStaleTicks = 0;
        return;
      }
      final posMs = _player.position.inMilliseconds;
      if (posMs < 200) return; // Skip silence at track start

      final lastMs = _watchdogLastMs;
      final delta = lastMs == null ? 999 : (posMs - lastMs).abs();
      if (delta < 100) {
        // Position hasn't moved meaningfully — track may have ended
        _watchdogStaleTicks++;
        print('[QuranAudio] watchdog tick $_watchdogStaleTicks at ${posMs}ms');
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
    print(
        '[QuranAudio] playerState playing=${state.playing} proc=${state.processingState}');

    // Layer 2: playing true→false without intentional stop.
    if (_wasPlaying && !state.playing && !_intentionalStop) {
      _fireAutoNext('playing→stopped');
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

  /// Load [url] and play. Uses a 300 ms timeout on setUrl so the 10-second
  /// iOS 26 continuation-leak hang doesn't create a gap between verses.
  /// AVPlayer continues loading in the background; play() streams when ready.
  Future<void> playFromUrl(String url, MediaItem item) async {
    print('[QuranAudio] playFromUrl url=$url');
    _intentionalStop = true;
    _completionFired = false;
    _wasPlaying = false;
    _watchdogTimer?.cancel();
    _watchdogLastMs = null;
    _watchdogStaleTicks = 0;
    mediaItem.add(item);
    try {
      // Short timeout: iOS 26 continuation leaks, but AVPlayer still loads.
      await _player.setUrl(url).timeout(const Duration(milliseconds: 300));
      print('[QuranAudio] setUrl done');
    } catch (e) {
      print('[QuranAudio] setUrl timeout (expected on iOS 26) — playing anyway');
    }
    try {
      await _player.play().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[QuranAudio] play() error/timeout: $e');
    }
    _intentionalStop = false;
    _startWatchdog();
    print('[QuranAudio] play() returned, watchdog started');
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
  Future<void> skipToNext() async {
    _commandController.add('nextSurah');
  }

  @override
  Future<void> skipToPrevious() async {
    _commandController.add('prevSurah');
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  void dispose() {
    _watchdogTimer?.cancel();
    _commandController.close();
    _player.dispose();
  }
}
