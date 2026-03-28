import AVFoundation
import MediaPlayer
import Flutter

/// Directly controls MPNowPlayingInfoCenter and MPRemoteCommandCenter
/// via a Flutter method channel, bypassing audio_service/just_audio_background
/// UIApplicationDelegate hooks that don't fire in the iOS 26 scene architecture.
class NowPlayingPlugin: NSObject, FlutterPlugin {

  private static var eventChannel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    NSLog("[NowPlayingPlugin] register called")
    let channel = FlutterMethodChannel(
      name: "co.getquran.app/nowplaying",
      binaryMessenger: registrar.messenger()
    )
    let instance = NowPlayingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel = channel

    // Activate audio session with .playback so MPNowPlayingInfoCenter works.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [])
      try session.setActive(true)
      NSLog("[NowPlayingPlugin] AVAudioSession active, category=playback")
    } catch {
      NSLog("[NowPlayingPlugin] AVAudioSession error: \(error)")
    }

    // Register remote command handlers — at least one must be enabled for
    // the system to show the Now Playing widget.
    let cmd = MPRemoteCommandCenter.shared()
    cmd.playCommand.isEnabled = true
    cmd.pauseCommand.isEnabled = true
    cmd.nextTrackCommand.isEnabled = true
    cmd.previousTrackCommand.isEnabled = true

    cmd.playCommand.addTarget { _ in
      NSLog("[NowPlayingPlugin] remoteCommand: play")
      eventChannel?.invokeMethod("play", arguments: nil)
      return .success
    }
    cmd.pauseCommand.addTarget { _ in
      NSLog("[NowPlayingPlugin] remoteCommand: pause")
      eventChannel?.invokeMethod("pause", arguments: nil)
      return .success
    }
    cmd.nextTrackCommand.addTarget { _ in
      NSLog("[NowPlayingPlugin] remoteCommand: next")
      eventChannel?.invokeMethod("next", arguments: nil)
      return .success
    }
    cmd.previousTrackCommand.addTarget { _ in
      NSLog("[NowPlayingPlugin] remoteCommand: previous")
      eventChannel?.invokeMethod("previous", arguments: nil)
      return .success
    }
    NSLog("[NowPlayingPlugin] remote commands registered")
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("[NowPlayingPlugin] handle: \(call.method)")
    switch call.method {
    case "setNowPlaying":
      let args = call.arguments as? [String: Any] ?? [:]
      let title  = args["title"]  as? String ?? ""
      let artist = args["artist"] as? String ?? ""
      let album  = args["album"]  as? String ?? ""
      let playing = args["playing"] as? Bool ?? true

      var info: [String: Any] = [
        MPMediaItemPropertyTitle:               title,
        MPMediaItemPropertyArtist:              artist,
        MPMediaItemPropertyAlbumTitle:          album,
        MPNowPlayingInfoPropertyPlaybackRate:        playing ? 1.0 : 0.0,
        MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
      ]
      if let secs = args["duration"] as? Double, secs > 0 {
        info[MPMediaItemPropertyPlaybackDuration] = secs
      }
      if let pos = args["position"] as? Double {
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = pos
      }

      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
      // iOS 13+: also set playbackState on the center itself.
      MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused

      NSLog("[NowPlayingPlugin] nowPlayingInfo set: title=\(title) artist=\(artist) playing=\(playing)")
      result(nil)

    case "clearNowPlaying":
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      MPNowPlayingInfoCenter.default().playbackState = .stopped
      NSLog("[NowPlayingPlugin] nowPlayingInfo cleared")
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
