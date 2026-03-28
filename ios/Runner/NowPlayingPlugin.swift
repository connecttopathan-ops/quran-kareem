import AVFoundation
import MediaPlayer
import Flutter

/// Directly controls MPNowPlayingInfoCenter and MPRemoteCommandCenter
/// via a Flutter method channel, bypassing audio_service/just_audio_background
/// UIApplicationDelegate hooks that don't fire in the iOS 26 scene architecture.
class NowPlayingPlugin: NSObject, FlutterPlugin {

  private static var eventChannel: FlutterMethodChannel?
  private static var commandsRegistered = false
  private static var setupCount = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    NSLog("[NowPlayingPlugin] register called")
    let channel = FlutterMethodChannel(
      name: "co.getquran.app/nowplaying",
      binaryMessenger: registrar.messenger()
    )
    let instance = NowPlayingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel = channel

    // Activate audio session with .playback so background audio and
    // MPNowPlayingInfoCenter work correctly.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [])
      try session.setActive(true)
      NSLog("[NowPlayingPlugin] AVAudioSession active, category=playback")
    } catch {
      NSLog("[NowPlayingPlugin] AVAudioSession error: \(error)")
    }
  }

  /// Re-registers remote command handlers, clearing any previously registered
  /// handlers (including those from just_audio_background) so ours take effect.
  /// Called on every setNowPlaying so we always override just_audio_background.
  private static func setupRemoteCommandsIfNeeded() {
    setupCount += 1
    // Re-register on first call and every 5th call thereafter, in case
    // just_audio_background re-registers its own handlers between verse changes.
    guard !commandsRegistered || setupCount % 5 == 0 else { return }
    commandsRegistered = true
    NSLog("[NowPlayingPlugin] setupRemoteCommands (call #\(setupCount))")

    let cmd = MPRemoteCommandCenter.shared()

    // Clear handlers registered by just_audio_background so ours are the only ones.
    cmd.playCommand.removeTarget(nil)
    cmd.pauseCommand.removeTarget(nil)
    cmd.togglePlayPauseCommand.removeTarget(nil)
    cmd.nextTrackCommand.removeTarget(nil)
    cmd.previousTrackCommand.removeTarget(nil)
    cmd.stopCommand.removeTarget(nil)
    cmd.changePlaybackPositionCommand.removeTarget(nil)
    cmd.skipForwardCommand.removeTarget(nil)
    cmd.skipBackwardCommand.removeTarget(nil)

    cmd.playCommand.isEnabled = true
    cmd.pauseCommand.isEnabled = true
    cmd.togglePlayPauseCommand.isEnabled = true
    cmd.nextTrackCommand.isEnabled = true
    cmd.previousTrackCommand.isEnabled = true
    cmd.stopCommand.isEnabled = false
    cmd.changePlaybackPositionCommand.isEnabled = false
    cmd.skipForwardCommand.isEnabled = false
    cmd.skipBackwardCommand.isEnabled = false

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
    cmd.togglePlayPauseCommand.addTarget { _ in
      NSLog("[NowPlayingPlugin] remoteCommand: togglePlayPause")
      eventChannel?.invokeMethod("togglePlayPause", arguments: nil)
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
      // Register remote commands now — just_audio_background has already
      // initialised by the time the first setNowPlaying call arrives.
      NowPlayingPlugin.setupRemoteCommandsIfNeeded()

      let args = call.arguments as? [String: Any] ?? [:]
      let title  = args["title"]  as? String ?? ""
      let artist = args["artist"] as? String ?? ""
      let album  = args["album"]  as? String ?? ""
      let playing = args["playing"] as? Bool ?? true

      var info: [String: Any] = [
        MPMediaItemPropertyTitle:                    title,
        MPMediaItemPropertyArtist:                   artist,
        MPMediaItemPropertyAlbumTitle:               album,
        MPNowPlayingInfoPropertyPlaybackRate:         playing ? 1.0 : 0.0,
        MPNowPlayingInfoPropertyDefaultPlaybackRate:  1.0,
      ]
      if let secs = args["duration"] as? Double, secs > 0 {
        info[MPMediaItemPropertyPlaybackDuration] = secs
      }
      if let pos = args["position"] as? Double {
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = pos
      }

      // Set a light-background artwork so iOS renders the control icons
      // (play/pause/skip) in a contrasting dark colour that is visible.
      let artSize = CGSize(width: 300, height: 300)
      UIGraphicsBeginImageContextWithOptions(artSize, false, 0)
      if let ctx = UIGraphicsGetCurrentContext() {
        // Gold crescent background matching the app theme
        UIColor(red: 0.96, green: 0.84, blue: 0.50, alpha: 1.0).setFill()
        ctx.fill(CGRect(origin: .zero, size: artSize))
        let label = "Quran" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
          .font: UIFont.boldSystemFont(ofSize: 48),
          .foregroundColor: UIColor(red: 0.1, green: 0.05, blue: 0.0, alpha: 1.0),
        ]
        let textSize = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: (artSize.width - textSize.width) / 2,
                               y: (artSize.height - textSize.height) / 2),
                   withAttributes: attrs)
      }
      let artImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
      UIGraphicsEndImageContext()
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artSize) { _ in artImage }

      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
