import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

  // iOS 26: setUpPlayerItemStatusObservation Swift continuation leaks, meaning
  // processingState.completed may never fire. Track completion via playing→false
  // transition as a backup. _intentionalStop prevents false triggers during URL
  // loads and user-initiated pause/stop.
  bool _completionFired = false;
  bool _intentionalStop = false;
  bool _wasPlaying = false;

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
    // Primary completion detection (may not fire on iOS 26).
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingStateStream state=$state');
      if (state == ProcessingState.completed) {
        _fireAutoNext('processingState.completed');
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

    // Backup completion detection: playing transitioned true→false without an
    // intentional stop. Fires even when processingState.completed is broken.
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
  /// the playing→false transition during URL switching doesn't trigger autoNext.
  /// Times out after 10s in case iOS 26's setUpPlayerItemStatusObservation
  /// continuation hangs indefinitely.
  Future<void> playFromUrl(String url, MediaItem item) async {
    print('[QuranAudio] playFromUrl url=$url');
    _intentionalStop = true;
    _completionFired = false;
    _wasPlaying = false;
    mediaItem.add(item);
    try {
      await _player.setUrl(url).timeout(const Duration(seconds: 10));
      print('[QuranAudio] setUrl done');
    } catch (e) {
      print('[QuranAudio] setUrl error/timeout: $e — calling play anyway');
    }
    await _player.play();
    _intentionalStop = false;
    print('[QuranAudio] play() returned, completion detection active');
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
