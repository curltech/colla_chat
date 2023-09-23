import UIKit
import flutter_sharing_intent
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
        // This is required to make any communication available in the action isolate.
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
      GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
   
 override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

     let sharingIntent = SwiftFlutterSharingIntentPlugin.instance
     /// if the url is made from SwiftFlutterSharingIntentPlugin then handle it with plugin [SwiftFlutterSharingIntentPlugin]
     if sharingIntent.hasSameSchemePrefix(url: url) {
         return sharingIntent.application(app, open: url, options: options)
     }

     // Proceed url handling for other Flutter libraries like uni_links
     return super.application(app, open: url, options:options)
   }

   func registerPlugins(registry: FlutterPluginRegistry) {
     GeneratedPluginRegistrant.register(with: registry)
   }
}
