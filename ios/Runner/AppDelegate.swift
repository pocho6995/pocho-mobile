import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Обязательно до регистрации плагинов — иначе Maps SDK крашит приложение.
    let mapsApiKey =
      (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if let mapsApiKey, !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
