import UIKit
import Flutter
import GoogleCast

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, GCKLoggerDelegate {
  let kReceiverAppID = "CC1AD845" 
  let kDebugLoggingEnabled = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    GCKCastContext.setSharedInstanceWith(options)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
