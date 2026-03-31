import Flutter
import UIKit
import WidgetKit

/// Handles the "co.getquran.app/widget" MethodChannel from Flutter.
/// Writes prayer / qibla data to the shared App Group UserDefaults so the
/// WidgetKit extension can read them without launching the full app.
class WidgetPlugin: NSObject, FlutterPlugin {

    private static let appGroup = "group.co.getquran.app"
    private static let channel  = "co.getquran.app/widget"

    static func register(with registrar: FlutterPluginRegistrar) {
        let ch = FlutterMethodChannel(name: channel,
                                      binaryMessenger: registrar.messenger())
        let instance = WidgetPlugin()
        registrar.addMethodCallDelegate(instance, channel: ch)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateWidgets":
            if let args = call.arguments as? [String: Any] {
                saveToAppGroup(args)
            }
            reloadWidgets()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func saveToAppGroup(_ data: [String: Any]) {
        guard let defaults = UserDefaults(suiteName: Self.appGroup) else { return }
        for (key, value) in data {
            switch value {
            case let s as String:  defaults.set(s,      forKey: key)
            case let d as Double:  defaults.set(d,      forKey: key)
            case let i as Int:     defaults.set(i,      forKey: key)
            default: break
            }
        }
        defaults.synchronize()
    }

    private func reloadWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
