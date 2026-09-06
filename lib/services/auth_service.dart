import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'yaqin_token';
  static const _userIdKey = 'yaqin_user_id';
  static const _userNameKey = 'yaqin_user_name';
  static const _userRoleKey = 'yaqin_user_role';
  static const _langKey = 'yaqin_lang';

  final ApiService api;
  UserModel? currentUser;
  String? token;

  AuthService(this.api);

  int? get userId => currentUser?.id;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    if (token != null) {
      api.setToken(token);
      try {
        currentUser = await api.getMe();
        notifyListeners();
      } catch (_) {
        await logout();
      }
    }
  }

  Future<bool> get isLoggedIn async => token != null;

  Future<int?> get savedUserId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String> get savedLang async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'ru';
  }

  Future<void> _saveToken(String t, UserModel user) async {
    token = t;
    currentUser = user;
    api.setToken(t);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, t);
    await prefs.setInt(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userRoleKey, user.role);
    
    // Notify Background Service immediately
    try {
      FlutterBackgroundService().invoke('updateConfig', {'userId': user.id});
    } catch (e) {
      debugPrint('AuthService: Failed to notify background service: $e');
    }
    
    // Register FCM and APNs token after login with retry loop for iOS
    try {
      String? fcmToken;
      String? apnsToken;
      for (int i = 0; i < 15; i++) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          if (Platform.isIOS) {
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          }
        } catch (e) {
          debugPrint('FCM Token error: $e. Retrying...');
        }
        
        if (fcmToken != null) {
          if (Platform.isIOS) {
             if (apnsToken != null || i >= 5) break; // wait at most 10 seconds for apns
          } else {
             break;
          }
        }
        await Future.delayed(const Duration(seconds: 2));
      }
      
      debugPrint('AuthService: FCM=$fcmToken, APNS=$apnsToken');
      if (fcmToken != null) {
        await updateFCMToken(fcmToken, apnsToken: apnsToken);
      } else {
        debugPrint('AuthService: Still failed to get FCM token.');
      }
    } catch (e) {
      debugPrint('AuthService: Fatal error getting FCM token after login: $e');
    }
  }

  Future<void> saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
    if (token != null) {
      try {
        currentUser = await api.updateProfile(lang: lang);
      } catch (e) {
        debugPrint('Failed to sync language to backend: $e');
      }
    }
  }

  Future<UserModel> uploadAvatar(String imagePath) async {
    final user = await api.uploadAvatar(imagePath);
    currentUser = user;
    return user;
  }

  Future<UserModel> uploadCompanyBanner(String imagePath) async {
    final user = await api.uploadCompanyBanner(imagePath);
    currentUser = user;
    return user;
  }

  Future<UserModel> updateProfile({
    String? name,
    String? city,
    String? lang,
    String? accountType,
    String? companyLogo,
    String? companyBanner,
    String? companyDescription,
    double? latitude,
    double? longitude,
  }) async {
    final user = await api.updateProfile(
      name: name,
      city: city,
      lang: lang,
      accountType: accountType,
      companyLogo: companyLogo,
      companyBanner: companyBanner,
      companyDescription: companyDescription,
      latitude: latitude,
      longitude: longitude,
    );
    currentUser = user;
    return user;
  }

  /// Send SMS verification code
  Future<Map<String, dynamic>> sendCode(String phone) async {
    return await api.sendCode(phone);
  }

  Future<void> sendForgotPasswordCode(String phone) async {
    await api.sendForgotPasswordCode(phone);
  }

  Future<void> resetPassword(String phone, String code, String newPassword) async {
    await api.resetPassword(phone, code, newPassword);
  }

  Future<UserModel> login(String phone, String password) async {
    final data = await api.login(phone: phone, password: password);
    final user = UserModel.fromJson(data['user']);
    await _saveToken(data['access_token'], user);
    return user;
  }

  Future<UserModel> register({
    String? name,
    required String phone,
    required String password,
    required String code,
    String role = 'client',
    String? city,
    String lang = 'ru',
  }) async {
    final data = await api.register(
      name: name,
      phone: phone,
      password: password,
      code: code,
      role: role,
      city: city,
      lang: lang,
    );
    final user = UserModel.fromJson(data['user']);
    await _saveToken(data['access_token'], user);
    return user;
  }

  Future<UserModel?> refreshUser() async {
    if (token == null) return null;
    try {
      final user = await api.getMe();
      currentUser = user;
      
      // Update role in storage too
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, user.role);
      
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('Error refreshing user: $e');
      return currentUser;
    }
  }

  Future<void> updateFCMToken(String fcmToken, {String? apnsToken}) async {
    if (token == null) return;
    try {
      await api.updateFCMToken(fcmToken, apnsToken: apnsToken);
      debugPrint('AuthService: FCM Token updated successfully');
    } catch (e) {
      debugPrint('AuthService: Failed to update FCM token on backend: $e');
    }
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    api.setToken(null);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }

  Future<void> deleteAccount() async {
    if (token == null) return;
    try {
      await api.deleteAccount();
      await logout();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}
