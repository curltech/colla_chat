import UIKit
import flutter_sharing_intent
import Flutter
import flutter_local_notifications
import flutter_background_service_ios
import QMapKit
//import awesome_notifications
//import shared_preferences_ios

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      QMapServices.shared().apiKey = "QFSBZ-ZTGCT-JS2XU-LERCR-ISRAQ-EEFJA"
      // This is required to make any communication available in the action isolate.
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
      }
      SwiftFlutterBackgroundServicePlugin.taskIdentifier = "io.curltech.colla.task.identifier"
      SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
      }
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
      // This function registers the desired plugins to be used within a notification background action
//      SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
//         SwiftAwesomeNotificationsPlugin.register(
//           with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
//         FLTSharedPreferencesPlugin.register(
//           with: registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")!)
//      }
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
}
