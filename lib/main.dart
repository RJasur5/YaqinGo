import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/orders/create_order_screen.dart';
import 'screens/orders/available_orders_screen.dart';
import 'screens/orders/my_orders_screen.dart';
import 'screens/orders/accepted_orders_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/language_select_screen.dart';
import 'screens/app_reviews_screen.dart';
import 'services/socket_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/orders/chat_list_screen.dart';
import 'screens/job_applications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/connectivity_service.dart';
import 'widgets/no_internet_banner.dart';
import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST (required for both iOS and Android)
  try {
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBZrldZPvp09YIdYZgvag0MoKX7vH-6geQ',
          appId: '1:973494872827:ios:bc3affd0198c66bba9de5e',
          messagingSenderId: '973494872827',
          projectId: 'yaqin-app-22180',
          storageBucket: 'yaqin-app-22180.firebasestorage.app',
          iosBundleId: 'com.yaqin.findix',
        ),
      );
    } else {
      // Android — auto-reads from google-services.json
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  // Initialize services
  final apiService = ApiService();
  final authService = AuthService(apiService);
  
  // Load saved token to ApiService on startup
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token != null) {
    apiService.setToken(token);
  }
  
  // Initialize notification service for UI alerts and FCM (fire-and-forget, must NOT block runApp)
  NotificationService.instance.init(authService: authService);
  
  // Read native iOS notification payload IMMEDIATELY (AppDelegate saved it to UserDefaults)
  // This is synchronous since SharedPreferences is already loaded above
  final nativePayload = prefs.getString('pending_notification_payload');
  if (nativePayload != null && nativePayload.isNotEmpty) {
    debugPrint('MAIN: Found native notification payload from cold start: $nativePayload');
    NotificationService.instance.setNativePendingPayload(nativePayload);
    await prefs.remove('pending_notification_payload');
  }
  
  // Initialize Theme Service
  final themeService = ThemeService();
  await themeService.init();
  
  // Global error handler — prevent app from crashing on unhandled errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  // Initialize Background Service (async, fire-and-forget) — wrapped to prevent native crash
  try {
    initializeService();
  } catch (e) {
    debugPrint('Background service init failed: $e');
  }

  // Initialize Date Formatting
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('uz', null);

  // Initialize Connectivity Service
  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    debugPrint('Connectivity service init failed: $e');
  }

  runApp(YaqinApp(apiService: apiService, authService: authService, themeService: themeService));
}

Future<void> initializeService() async {
  if (Platform.isAndroid) {
    // Skip background service on Android — causes native crash on Android 14+
    // Firebase FCM handles push notifications, WebSocket runs in main isolate
    debugPrint('Skipping background service on Android (not needed, FCM handles notifications)');
    return;
  }
  
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: false,
      notificationChannelId: 'yaqin_foreground',
      initialNotificationTitle: 'Yaqin Go',
      initialNotificationContent: 'Qidiruv yangi buyurtmalar...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    // CRITICAL: Call immediately on Android 14+ — must be called within 5 seconds!
    service.setAsForegroundService();
    
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    
    service.setForegroundNotificationInfo(
      title: "Yaqin Go",
      content: "Сервис запущен. Ждем данные...",
    );
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  try {
    final apiService = ApiService();
    final authService = AuthService(apiService);
    await NotificationService().init(requestPermission: false, authService: authService);

    
    service.on('updateConfig').listen((event) async {
       final userId = event?['userId'];
       if (userId != null && userId is int) {
          SocketService().connect(userId);
       }
    });

    service.on('connect').listen((event) async {
       final userId = event?['user_id'];
       if (userId != null && userId is int) {
          SocketService().connect(userId);
       }
    });

    service.on('disconnect').listen((event) {
       SocketService().disconnect();
    });

    // Check saved user on start
    final userId = await authService.savedUserId;
    if (userId != null) {
       SocketService().connect(userId);
    } else {
       SocketService().disconnect();
    }

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Yaqin Go",
            content: "Поиск новых заказов...",
          );
        }
      }
    });
  } catch (e) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Yaqin Go: Ошибка запуска",
        content: e.toString(),
      );
    }
  }
}

class YaqinApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  final ThemeService themeService;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  const YaqinApp({super.key, required this.apiService, required this.authService, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeService.themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          navigatorKey: YaqinApp.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Yaqin Go',
          builder: (context, child) => NoInternetBanner(child: child!),
          theme: AppTheme.getTheme(mode),
          themeMode: ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(authService: authService),
            '/login': (context) => LoginScreen(authService: authService),
            '/register': (context) => RegisterScreen(authService: authService),
            '/home': (context) => HomeScreen(apiService: apiService, authService: authService),
            '/create-order': (context) => CreateOrderScreen(apiService: apiService, authService: authService),
            '/available-orders': (context) => AvailableOrdersScreen(apiService: apiService, authService: authService),
            '/my-orders': (context) => MyOrdersScreen(apiService: apiService, authService: authService),
            '/accepted-orders': (context) => AcceptedOrdersScreen(apiService: apiService, authService: authService),
            '/onboarding': (context) => const OnboardingScreen(),
            '/language-select': (context) => LanguageSelectScreen(authService: authService),
            '/app-reviews': (context) => AppReviewsScreen(apiService: apiService),
            '/chats': (context) => ChatListScreen(
              apiService: apiService, 
              currentUserId: authService.userId ?? 0
            ),
            '/job-applications': (context) => JobApplicationsScreen(apiService: apiService),
            '/profile': (context) => ProfileScreen(authService: authService, apiService: apiService),
          },
        );
      },
    );
  }
}
