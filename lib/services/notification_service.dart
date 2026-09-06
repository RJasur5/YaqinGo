import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../main.dart';
import 'dart:convert';
import '../screens/home_screen.dart';
import 'local_notifications_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Show local notification if we receive a data message without a notification object
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'Yaqin Go';
    final body = message.data['body'] ?? message.data['message'] ?? 'Новое уведомление';
    
    // Save to local store
    await LocalNotificationsStore.saveNotification(
      LocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.toString(),
        body: body.toString(),
        timestamp: DateTime.now(),
        data: message.data,
      ),
    );

    // Get unread count for badge
    final unreadCount = await LocalNotificationsStore.getUnreadCount();

    // Show using local notifications
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: unreadCount,
    );
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'yaqin_channel', 'Yaqin Notifications',
      importance: Importance.max, priority: Priority.high,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      iOS: darwinPlatformChannelSpecifics,
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title.toString(),
      body.toString(),
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }
}


class NotificationService {
  // FIX: Single instance only
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  dynamic _pendingPayload;
  bool _isNavigationInProgress = false;
  static bool isReadyForNavigation = false;

  // Track the current chat to suppress notifications while reading
  static int? activeChatOrderId;

  /// Called from main() to set notification payload read from native iOS UserDefaults
  void setNativePendingPayload(String jsonPayload) {
    try {
      final parsed = json.decode(jsonPayload);
      if (parsed is Map && parsed.isNotEmpty) {
        _pendingPayload = Map<String, dynamic>.from(parsed);
        debugPrint('NOTIFICATION_SERVICE: Native payload set from main(): $_pendingPayload');
      }
    } catch (e) {
      debugPrint('NOTIFICATION_SERVICE: Error parsing native payload in setNativePendingPayload: $e');
    }
  }

  Future<void> init({bool requestPermission = true, AuthService? authService}) async {
    if (kIsWeb) return; 

    // Initialize Firebase if not already initialized
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase already initialized or error: $e');
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for token refresh and update backend
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (authService != null) {
        authService.updateFCMToken(newToken);
      }
    });

    // Request permissions for iOS
    if (Platform.isIOS) {
       await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
       );
    }

    // Fetch FCM Token asynchronously to not block app launch
    () async {
      try {
        if (Platform.isIOS) {
          String? apnsToken;
          // Wait up to 30 seconds for APNS token asynchronously without blocking app launch
          for (int i = 0; i < 30; i++) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) break;
          }
          if (apnsToken == null) {
            print("APNS token is still null after 30s. Push notifications won't work.");
            return;
          }
          print("APNS Token acquired: $apnsToken");
        }
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null && authService != null) {
           print("FCM Token: $token");
           await authService.updateFCMToken(token);
        }
      } catch (e) {
        print("Error getting FCM token: $e");
      }
    }();

    // Handle foreground messages — SUPPRESS system push to avoid duplicates
    // SocketService already handles all foreground events via WebSocket + showNotification()
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('NOTIFICATION_SERVICE: Foreground FCM received type=${message.data['type']} (suppressed to avoid duplicate)');
      // DO NOT show notification here — SocketService already shows it via WebSocket
    });

    // iOS: Explicitly disable foreground push presentation to prevent duplicates
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }


    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handlePayload(response.payload);
      },
    );

    // 1. CAPTURE TERMINATED STATE MESSAGE - try Firebase first
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      debugPrint('NOTIFICATION_SERVICE: Captured initial message via Firebase');
      _pendingPayload = initialMessage.data;
    } else {
      // 2. CHECK NATIVE iOS UserDefaults (our AppDelegate stores notification taps here)
      await _checkNativeNotificationPayload();
    }
    
    if (_pendingPayload == null) {
      // 3. CHECK LOCAL NOTIFICATIONS AS FALLBACK
      final NotificationAppLaunchDetails? details = 
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        debugPrint('NOTIFICATION_SERVICE: Captured local notification launch');
        _pendingPayload = details.notificationResponse?.payload;
      }
    }

    // Handle clicks when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       handlePayload(message.data);
    });

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      // Create the channel for the foreground service
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'yaqin_foreground', // same as in main.dart
        'Yaqin Go Background Service',
        description: 'This channel is used for the foreground service.',
        importance: Importance.low, 
      );

      // Create the channel for actual ORDER notifications (CRITICAL FIX)
      const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
        'yaqin_orders_channel',
        'Yaqin Go Order Notifications',
        description: 'Notifications for new orders matching your specialty',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.createNotificationChannel(ordersChannel);
      
      // ONLY request permission if we are in the main UI thread
      if (requestPermission) {
        await androidPlugin?.requestNotificationsPermission();
      }
    }
  }

  /// Read notification payload saved by native iOS AppDelegate
  Future<void> _checkNativeNotificationPayload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nativePayload = prefs.getString('pending_notification_payload');
      if (nativePayload != null && nativePayload.isNotEmpty) {
        debugPrint('NOTIFICATION_SERVICE: Found native iOS notification payload: $nativePayload');
        // Clear it immediately so it's not processed again
        await prefs.remove('pending_notification_payload');
        
        try {
          final parsed = json.decode(nativePayload);
          if (parsed is Map) {
            _pendingPayload = Map<String, dynamic>.from(parsed);
            debugPrint('NOTIFICATION_SERVICE: Parsed native payload: $_pendingPayload');
          }
        } catch (e) {
          debugPrint('NOTIFICATION_SERVICE: Error parsing native payload: $e');
        }
      }
    } catch (e) {
      debugPrint('NOTIFICATION_SERVICE: Error reading native notification payload: $e');
    }
  }

  Future<void> handlePayload(dynamic data) async {
    if (data == null) return;
    
    // Convert string to map if needed
    Map<String, dynamic> finalData = {};
    if (data is String) {
      if (data.isEmpty) return;
      try {
        final parsed = json.decode(data);
        if (parsed is Map) {
          finalData = Map<String, dynamic>.from(parsed);
        } else {
          finalData['type'] = data;
        }
      } catch (_) {
        finalData['type'] = data;
      }
    } else if (data is Map) {
      finalData = Map<String, dynamic>.from(data);
    }

    final type = finalData['type']?.toString();
    if (type == null) return;

    var nav = YaqinApp.navigatorKey.currentState;
    
    // If navigator is not ready or we are still on Splash Screen, store as pending
    if (nav == null || !isReadyForNavigation) {
      debugPrint('NOTIFICATION_SERVICE: App not ready for navigation, storing as pending: $type');
      _pendingPayload = finalData;
      return;
    }

    if (_isNavigationInProgress) {
      debugPrint('NOTIFICATION_SERVICE: Navigation already in progress, queuing payload');
      _pendingPayload = finalData;
      return;
    }
    
    _isNavigationInProgress = true;

    try {
      debugPrint('NOTIFICATION_SERVICE: Executing navigation for type: $type');
      
      // Delay slightly to ensure any current transitions are finished
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Helper: Navigate to HomeScreen on a specific tab (preserves BottomNavigationBar)
      void goToHomeTab(int tabIndex) {
        // Pop any overlaying screens (like chats or dialogs) until we are at the home screen
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        // Safely call the tab switch closure
        HomeScreen.switchToTab?.call(tabIndex);
      }
      
      // =====================================================
      // NOTIFICATION ROUTING — matches backend notification types exactly
      // =====================================================
      
      // 1) new_order: A new order appeared matching worker's specialty → Available Orders (Tab 3)
      if (type == 'new_order' || type == 'available_orders' || finalData['payload'] == 'available_orders') {
        goToHomeTab(3);
      }
      // 2) chat_message: Someone sent a chat message → Chats (Tab 2)
      else if (type == 'chat_message' || type.startsWith('chat_')) {
        goToHomeTab(2);
      }
      // 3) order_accepted: A worker accepted employer's order / HR got a new applicant → My Orders
      else if (type == 'order_accepted') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/my-orders');
      }
      // 4) order_completed: Order auto-completed → Profile (Tab 4)  
      else if (type == 'order_completed') {
        goToHomeTab(4);
      }
      // 5) hr_accepted: HR formally accepted a worker → Profile (Tab 4) for the worker
      else if (type == 'hr_accepted') {
        goToHomeTab(4);
      }
      // 6) order_rejected: Employer rejected worker → Profile (Tab 4)
      else if (type == 'order_rejected') {
        goToHomeTab(4);
      }
      // 7) vacancy_closed: HR vacancy expired → Profile (Tab 4)
      else if (type == 'vacancy_closed') {
        goToHomeTab(4);
      }
      // 8) order_cancelled: Client cancelled order → Profile (Tab 4) 
      else if (type == 'order_cancelled') {
        goToHomeTab(4);
      }
      // 9) job_application: Employer sent a job request to master → Job Applications screen
      else if (type == 'job_application') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/job-applications');
      }
      // 10) job_application_status: Master responded to employer's application → My Orders
      else if (type == 'job_application_status') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/my-orders');
      }
      // 11) job_application_withdrawn: Employer withdrew application → Job Applications screen
      else if (type == 'job_application_withdrawn') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/job-applications');
      }
      // 12) hr_expiry_warning: HR vacancy expiring soon → My Orders
      else if (type == 'hr_expiry_warning') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/my-orders');
      }
      // 13) Legacy types
      else if (type == 'my_orders') {
        nav.popUntil((route) => route.settings.name == '/home' || route.isFirst);
        await nav.pushNamed('/my-orders');
      }
      else if (type == 'profile') {
        goToHomeTab(4);
      }
      else {
        debugPrint('NOTIFICATION_SERVICE: No specific navigation for type: $type');
      }
    } finally {
      // Small cooldown to prevent double transitions
      await Future.delayed(const Duration(milliseconds: 500));
      _isNavigationInProgress = false;
      _pendingPayload = null; // Clear queue after success
    }
  }

  /// Called when the Navigator is definitely ready (e.g. from HomeScreen or the main builder)
  Future<void> processPendingNavigation({int retryCount = 0}) async {
    // If pending payload is null, try ALL sources one more time
    if (_pendingPayload == null) {
      // 1. Try Firebase getInitialMessage
      try {
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null && initialMessage.data.isNotEmpty) {
          debugPrint('NOTIFICATION_SERVICE: Late capture via Firebase getInitialMessage');
          _pendingPayload = initialMessage.data;
        }
      } catch (e) {
        debugPrint('NOTIFICATION_SERVICE: Error in late getInitialMessage: $e');
      }
      
      // 2. Try native iOS UserDefaults (AppDelegate saved it there)
      if (_pendingPayload == null) {
        await _checkNativeNotificationPayload();
      }
      
      // 3. Try flutter_local_notifications launch details
      if (_pendingPayload == null) {
        try {
          final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
          if (details != null && details.didNotificationLaunchApp && details.notificationResponse?.payload != null) {
            debugPrint('NOTIFICATION_SERVICE: Late capture via local notification launch details');
            _pendingPayload = details.notificationResponse!.payload;
          }
        } catch (e) {
          debugPrint('NOTIFICATION_SERVICE: Error in late launch details: $e');
        }
      }
    }

    if (_pendingPayload != null) {
      debugPrint('NOTIFICATION_SERVICE: Processing pending navigation (Attempt ${retryCount + 1}), payload: $_pendingPayload');
      
      if (YaqinApp.navigatorKey.currentState == null || !isReadyForNavigation) {
        if (retryCount < 10) {
          debugPrint('NOTIFICATION_SERVICE: App still not ready, retrying in 500ms...');
          await Future.delayed(const Duration(milliseconds: 500));
          return processPendingNavigation(retryCount: retryCount + 1);
        } else {
          debugPrint('NOTIFICATION_SERVICE: App failed to be ready after 10 retries.');
          return;
        }
      }
      
      await handlePayload(_pendingPayload);
    } else {
      debugPrint('NOTIFICATION_SERVICE: No pending payload found from any source.');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb) return; // Skip on Web

    final String? payload = data != null ? json.encode(data) : null;
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'yaqin_orders_channel',
      'Yaqin Go Order Notifications',
      channelDescription: 'Notifications for new orders matching your specialty',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    final unreadCount = await LocalNotificationsStore.getUnreadCount();

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: unreadCount,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );


    await LocalNotificationsStore.saveNotification(
      LocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        data: data ?? {},
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
