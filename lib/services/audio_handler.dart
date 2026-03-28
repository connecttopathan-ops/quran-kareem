import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String> _commandController =
      StreamController<String>.broadcast();

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
    // When a single verse finishes, signal auto-advance.
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingStateStream state=$state');
      if (state == ProcessingState.completed) {
        print('[QuranAudio] >> sending autoNext');
        _commandController.add('autoNext');
      }
    });
  }

  /// Load [url] and start playing immediately. Does NOT call stop() first so
  /// the AVAudioSession stays active on iOS, preventing background suspension.
  Future<void> playFromUrl(String url, MediaItem item) async {
    print('[QuranAudio] playFromUrl url=$url');
    mediaItem.add(item);
    await _player.setUrl(url);
    print('[QuranAudio] setUrl done, calling play');
    await _player.play();
    print('[QuranAudio] play() returned');
  }

  void _syncPlaybackState(PlayerState state) {
    print(
        '[QuranAudio] playerState playing=${state.playing} proc=${state.processingState}');
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

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
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
