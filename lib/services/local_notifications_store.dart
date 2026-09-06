import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool isRead;

  LocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
        'isRead': isRead,
      };

  factory LocalNotification.fromJson(Map<String, dynamic> json) => LocalNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        timestamp: DateTime.parse(json['timestamp']),
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        isRead: json['isRead'] ?? false,
      );
}

class LocalNotificationsStore {
  static const String _key = 'local_notifications';

  static Future<List<LocalNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((str) => LocalNotification.fromJson(jsonDecode(str))).toList();
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  static Future<void> saveNotification(LocalNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    
    // Add new notification at the beginning
    jsonList.insert(0, jsonEncode(notification.toJson()));
    
    // Keep only the last 100 notifications
    if (jsonList.length > 100) {
      jsonList.removeLast();
    }
    
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final updatedList = jsonList.map((str) {
      final notif = LocalNotification.fromJson(jsonDecode(str));
      notif.isRead = true;
      return jsonEncode(notif.toJson());
    }).toList();
    
    await prefs.setStringList(_key, updatedList);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
