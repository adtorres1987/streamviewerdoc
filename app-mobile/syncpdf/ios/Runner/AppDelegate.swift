import Firebase
import Flutter
import UIKit

// AppDelegate configures Firebase and delegates engine registration to Flutter.
// Firebase.configure() must be called before any other Firebase API.
// Requires GoogleService-Info.plist to be present in the Runner target —
// obtain this file from Firebase Console → Project settings → iOS app.

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
