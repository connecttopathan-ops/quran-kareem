import AVFoundation
import MediaPlayer
import Flutter

/// Directly controls MPNowPlayingInfoCenter and MPRemoteCommandCenter
/// via a Flutter method channel, bypassing audio_service/just_audio_background
/// UIApplicationDelegate hooks that don't fire in the iOS 26 scene architecture.
class NowPlayingPlugin: NSObject, FlutterPlugin {

  private static var eventChannel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "co.getquran.app/nowplaying",
      binaryMessenger: registrar.messenger()
    )
    let instance = NowPlayingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel = channel

    // Ensure audio session category is .playback so the system shows
    // the Now Playing widget on the lock screen.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: []
      )
    } catch {
      print("[NowPlayingPlugin] AVAudioSession setCategory error: \(error)")
    }

    // Register remote command handlers so the lock screen controls work.
    let cmd = MPRemoteCommandCenter.shared()
    cmd.playCommand.isEnabled = true
    cmd.pauseCommand.isEnabled = true
    cmd.nextTrackCommand.isEnabled = true
    cmd.previousTrackCommand.isEnabled = true

    cmd.playCommand.addTarget { _ in
      eventChannel?.invokeMethod("play", arguments: nil)
      return .success
    }
    cmd.pauseCommand.addTarget { _ in
      eventChannel?.invokeMethod("pause", arguments: nil)
      return .success
    }
    cmd.nextTrackCommand.addTarget { _ in
      eventChannel?.invokeMethod("next", arguments: nil)
      return .success
    }
    cmd.previousTrackCommand.addTarget { _ in
      eventChannel?.invokeMethod("previous", arguments: nil)
      return .success
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setNowPlaying":
      let args = call.arguments as? [String: Any] ?? [:]
      var info: [String: Any] = [:]
      info[MPMediaItemPropertyTitle]     = args["title"]  as? String ?? ""
      info[MPMediaItemPropertyArtist]    = args["artist"] as? String ?? ""
      info[MPMediaItemPropertyAlbumTitle] = args["album"] as? String ?? ""
      if let secs = args["duration"] as? Double, secs > 0 {
        info[MPMediaItemPropertyPlaybackDuration] = secs
      }
      if let pos = args["position"] as? Double {
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = pos
      }
      let playing = args["playing"] as? Bool ?? true
      info[MPNowPlayingInfoPropertyPlaybackRate]        = playing ? 1.0 : 0.0
      info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
      print("[NowPlayingPlugin] nowPlayingInfo set: \(info[MPMediaItemPropertyTitle] ?? "") – \(info[MPMediaItemPropertyArtist] ?? "")")
      result(nil)

    case "clearNowPlaying":
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
