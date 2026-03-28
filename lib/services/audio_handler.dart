import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

  // iOS 26: setUpPlayerItemStatusObservation Swift continuation leaks, meaning
  // processingState.completed may never fire AND playing may never go false.
  // Three-layer detection:
  //   1. processingState.completed stream
  //   2. playing true→false transition
  //   3. Position-staleness watchdog (position stops advancing = audio ended)
  bool _completionFired = false;
  bool _intentionalStop = false;
  bool _wasPlaying = false;

  // Watchdog: detect end-of-track when neither event fires (iOS 26 worst case).
  Duration? _watchdogLastPos;
  int _watchdogStaleTicks = 0;
  static const int _kStaleTicks = 5; // ~1 s at just_audio's 200 ms poll rate

  Stream<String> get commands => _commandController.stream;
  AudioPlayer get player => _player;

  QuranAudioHandler() {
    _player.playerStateStream.listen(_syncPlaybackState);
    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
      _tickWatchdog(pos);
    });
    _player.bufferedPositionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(bufferedPosition: pos));
    });
    // Primary completion detection (may not fire on iOS 26).
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingStateStream state=$state');
      if (state == ProcessingState.completed) {
        _fireAutoNext('processingState.completed');
      }
    });
  }

  // Layer 3: position-staleness watchdog.
  // Fires autoNext when position stops advancing while supposedly playing.
  // Skip the first 500 ms of a track (position naturally starts at 0).
  void _tickWatchdog(Duration pos) {
    if (_intentionalStop || !_wasPlaying) {
      _resetWatchdog();
      return;
    }
    if (pos.inMilliseconds < 500) {
      _resetWatchdog();
      return;
    }
    if (_watchdogLastPos == pos) {
      _watchdogStaleTicks++;
      print('[QuranAudio] watchdog stale tick $_watchdogStaleTicks at $pos');
      if (_watchdogStaleTicks >= _kStaleTicks) {
        print('[QuranAudio] watchdog fired at $pos');
        _resetWatchdog();
        _fireAutoNext('position-stale');
      }
    } else {
      _watchdogStaleTicks = 0;
      _watchdogLastPos = pos;
    }
  }

  void _resetWatchdog() {
    _watchdogLastPos = null;
    _watchdogStaleTicks = 0;
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

  /// Load [url] and start playing. Sets _intentionalStop during the load so
  /// state transitions during URL switching don't trigger autoNext.
  /// Times out after 10 s in case iOS 26's continuation hangs indefinitely.
  Future<void> playFromUrl(String url, MediaItem item) async {
    print('[QuranAudio] playFromUrl url=$url');
    _intentionalStop = true;
    _completionFired = false;
    _wasPlaying = false;
    _resetWatchdog();
    mediaItem.add(item);
    try {
      await _player.setUrl(url).timeout(const Duration(seconds: 10));
      print('[QuranAudio] setUrl done');
    } catch (e) {
      print('[QuranAudio] setUrl error/timeout: $e — calling play anyway');
    }
    try {
      await _player.play().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[QuranAudio] play() error/timeout: $e');
    }
    _intentionalStop = false;
    print('[QuranAudio] play() returned, all detection layers active');
  }

  @override
  Future<void> play() async {
    _intentionalStop = false;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    _intentionalStop = true;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _intentionalStop = true;
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
    _commandController.close();
    _player.dispose();
  }
}
