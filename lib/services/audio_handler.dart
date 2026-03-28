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
      print('[QuranAudio] currentIndexStream index=$index queueLen=${_queue.length}');
      if (index != null && index > 0) {
        print('[QuranAudio] >> sending autoNext');
        _commandController.add('autoNext');
      }
    });
    // Entire queue finished (last verse of Quran or single verse with no next).
    _player.processingStateStream.listen((state) {
      print('[QuranAudio] processingStateStream state=$state');
      if (state == ProcessingState.completed) {
        print('[QuranAudio] >> sending completed');
        _commandController.add('completed');
      }
    });
  }

  /// Start playing [url] immediately, with optional [nextUrl] preloaded for
  /// gapless transition to the next verse. Clears any existing queue.
  Future<void> playFromUrl(String url, MediaItem item,
      {String? nextUrl}) async {
    print('[QuranAudio] playFromUrl url=$url nextUrl=$nextUrl');
    mediaItem.add(item);
    await _queue.clear();
    await _queue.add(AudioSource.uri(Uri.parse(url)));
    if (nextUrl != null) {
      await _queue.add(AudioSource.uri(Uri.parse(nextUrl)));
    }
    print('[QuranAudio] queue built len=${_queue.length}, calling setAudioSource');
    await _player.setAudioSource(_queue, preload: true);
    print('[QuranAudio] setAudioSource done, calling play');
    await _player.play();
    print('[QuranAudio] play() returned');
  }

  /// Append [url] to the end of the queue so just_audio can preload it
  /// while the current verse plays, eliminating the silence gap on iOS.
  Future<void> enqueueNext(String url) async {
    print('[QuranAudio] enqueueNext url=$url queueLenBefore=${_queue.length}');
    await _queue.add(AudioSource.uri(Uri.parse(url)));
    print('[QuranAudio] enqueueNext done queueLen=${_queue.length}');
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
