import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _queue =
      ConcatenatingAudioSource(children: []);
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
    // Gapless advance: player moved to next queued item — no silence gap on iOS.
    _player.currentIndexStream.listen((index) {
      if (index != null && index > 0) {
        _commandController.add('autoNext');
      }
    });
    // Entire queue finished (last verse of Quran or single verse with no next).
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _commandController.add('completed');
      }
    });
  }

  /// Start playing [url] immediately, with optional [nextUrl] preloaded for
  /// gapless transition to the next verse. Clears any existing queue.
  Future<void> playFromUrl(String url, MediaItem item,
      {String? nextUrl}) async {
    mediaItem.add(item);
    await _queue.clear();
    await _queue.add(AudioSource.uri(Uri.parse(url)));
    if (nextUrl != null) {
      await _queue.add(AudioSource.uri(Uri.parse(nextUrl)));
    }
    await _player.setAudioSource(_queue, preload: true);
    await _player.play();
  }

  /// Append [url] to the end of the queue so just_audio can preload it
  /// while the current verse plays, eliminating the silence gap on iOS.
  Future<void> enqueueNext(String url) async {
    await _queue.add(AudioSource.uri(Uri.parse(url)));
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
