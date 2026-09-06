import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Configure Firebase FIRST
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    // 2. Set up push notification delegate
    UNUserNotificationCenter.current().delegate = self

    // 3. Register for remote notifications with Apple
    application.registerForRemoteNotifications()

    // 4. Set Firebase Messaging delegate
    Messaging.messaging().delegate = self

    // 5. Check if app was launched from a notification tap (cold start)
    if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      print("APP_DELEGATE: Launched from notification tap (cold start)")
      saveNotificationPayload(remoteNotification)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called when APNs token is received from Apple
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Pass token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Called if APNs registration fails
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error.localizedDescription)")
  }

  // Firebase Messaging delegate - called when FCM token is received
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM Token received: \(fcmToken ?? "nil")")
  }

  // CRITICAL: Required for Flutter plugin registration
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // CRITICAL: Called when a notification arrives while app is IN FOREGROUND
  // We suppress REMOTE FCM push (to avoid duplicates with WebSocket-triggered local notifications)
  // But we ALLOW local notifications (from flutter_local_notifications) to display
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    let isRemotePush = userInfo["gcm.message_id"] != nil || userInfo["google.c.a.e"] != nil
    
    if isRemotePush {
      // This is a FCM remote push — suppress it (SocketService already shows a local notification)
      print("APP_DELEGATE: Foreground FCM push SUPPRESSED: \(userInfo["type"] ?? "unknown")")
      completionHandler([])
    } else {
      // This is a local notification from flutter_local_notifications — show it!
      print("APP_DELEGATE: Foreground LOCAL notification SHOWN")
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
    }
  }

  // CRITICAL: Called when user TAPS a notification (both background & terminated)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("APP_DELEGATE: Notification tapped! userInfo: \(userInfo)")
    saveNotificationPayload(userInfo)
    // Call super so Firebase plugin also gets the event
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // Store notification data in UserDefaults so Flutter can read it via SharedPreferences
  private func saveNotificationPayload(_ userInfo: [AnyHashable: Any]) {
    var notifData: [String: String] = [:]

    // Try to get "type" directly (FCM data payload puts it at top level)
    if let type = userInfo["type"] as? String {
      notifData["type"] = type
    }

    // Try to get "payload" (our backend's custom field)
    if let payload = userInfo["payload"] as? String {
      notifData["payload"] = payload
    }

    // If nothing found at top level, check "data" key (direct APNs format)
    if notifData["type"] == nil {
      if let dataDict = userInfo["data"] as? [String: Any] {
        if let type = dataDict["type"] as? String { notifData["type"] = type }
        if let payload = dataDict["payload"] as? String { notifData["payload"] = payload }
      }
    }

    // Last resort: stringify everything
    if notifData.isEmpty {
      for (key, value) in userInfo {
        let k = String(describing: key)
        if k != "aps" && k != "gcm.message_id" && k != "google.c.a.e" {
          notifData[k] = String(describing: value)
        }
      }
    }

    if !notifData.isEmpty {
      if let jsonData = try? JSONSerialization.data(withJSONObject: notifData),
         let jsonString = String(data: jsonData, encoding: .utf8) {
        // flutter. prefix is required for SharedPreferences compatibility
        UserDefaults.standard.set(jsonString, forKey: "flutter.pending_notification_payload")
        UserDefaults.standard.synchronize()
        print("APP_DELEGATE: Saved payload to UserDefaults: \(jsonString)")
      }
    }
  }
}
