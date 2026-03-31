import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Register our custom Now Playing plugin that bypasses the audio_service
    // UIApplicationDelegate hooks (which don't fire in the iOS 26 scene architecture).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NowPlayingPlugin") {
      NowPlayingPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WidgetPlugin") {
      WidgetPlugin.register(with: registrar)
    }
  }
}
