import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/localization.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/order_notification_overlay.dart';
import '../models/master.dart';
import '../services/api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  int? _connectedUserId;
  Timer? _pingTimer;
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;
  int? get connectedUserId => _connectedUserId;
  MasterModel? _currentMasterProfile;

  void setMasterProfile(MasterModel? profile) async {
    _currentMasterProfile = profile;
    debugPrint('SOCKET_SERVICE: Master profile set: ${profile?.subcategoryNameRu}');
    
    // Persist for background isolates
    final prefs = await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString('yaqin_master_profile', jsonEncode(profile.toJson()));
    } else {
      await prefs.remove('yaqin_master_profile');
    }
  }

  void connect(int userId) {
    if (_isConnected && _connectedUserId != userId) {
      disconnect();
    }
    
    if (_isConnected) return;

    _connectedUserId = userId;
    _currentMasterProfile = null; // Important: Clear profile for new user
    final wsUrl = ApiConfig.wsNotifications(userId);
    print('Connecting to WebSocket: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          if (message == 'pong') {
            debugPrint('SOCKET_SERVICE: Received pong');
            return;
          }
          _handleMessage(message);
        },
        onDone: () {
          debugPrint('SOCKET_SERVICE: Connection closed for user $userId');
          _stopPing();
          _isConnected = false;
          // Simple backoff or immediate reconnect for background reliability
          Future.delayed(const Duration(seconds: 3), () {
             if (_connectedUserId == userId) connect(userId);
          });
        },
        onError: (error) {
          debugPrint('SOCKET_SERVICE: Connection error: $error');
          _stopPing();
          _isConnected = false;
          Future.delayed(const Duration(seconds: 5), () {
             if (_connectedUserId == userId) connect(userId);
          });
        },
      );

      _startPing();
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  Future<void> _handleMessage(dynamic message) async {
    debugPrint('SOCKET_SERVICE: Received message: $message');
    try {
      final data = jsonDecode(message);
      
      // Load profile if missing (helps in background isolates)
      if (_currentMasterProfile == null) {
        final prefs = await SharedPreferences.getInstance();
        final profileStr = prefs.getString('yaqin_master_profile');
        if (profileStr != null) {
          _currentMasterProfile = MasterModel.fromJson(jsonDecode(profileStr));
        }
      }

      if (data['type'] == 'new_order') {
        _messageController.add(data); // BROADCAST TO UI
        
        // Show notification (System or Overlay)
        final nav = YaqinApp.navigatorKey.currentState;
        if (nav != null) {
          _showGlobalOverlay(data);
        } else {
          // BACKGROUND: Show system notification
          await NotificationService.instance.showNotification(
            id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
            title: AppStrings.isRu ? '⚡ Новый заказ!' : '⚡ Yangi buyurtma!',
            body: '${AppStrings.isRu ? (data['subcategory_name_ru'] ?? '') : (data['subcategory_name_uz'] ?? data['subcategory_name_ru'] ?? '')}: ${data['description']}',
            data: {'type': 'available_orders'},
          );
        }
      } else if (data['type'] == 'order_accepted') {
        _messageController.add(data); // BROADCAST TO UI
        final isCompany = data['is_company'] == 'True' || data['is_company'] == true;
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: isCompany ? (AppStrings.isRu ? 'Новый отклик!' : 'Yangi javob!') : '🤝 Yaqin Go',
          body: AppStrings.isRu 
            ? (isCompany ? 'Специалист ${data['master_name']} откликнулся на вашу вакансию!' : 'Мастер ${data['master_name']} принял ваш заказ: ${data['subcategory_name_ru']}')
            : (isCompany ? 'Mutaxassis ${data['master_name']} sizning vakansiyangizga javob berdi!' : 'Usta ${data['master_name']} buyurtmangizni qabul qildi: ${data['subcategory_name_uz']}'),
          data: {'type': 'my_orders'},
        );
      } else if (data['type'] == 'order_completed') {
        _messageController.add(data); // BROADCAST TO UI
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: '✅ Yaqin Go',
          body: AppStrings.orderCompleted,
          data: {'type': 'order_completed'},
        );
      } else if (data['type'] == 'order_rejected' || data['type'] == 'order_cancelled' || data['type'] == 'vacancy_closed') {
        _messageController.add(data); // BROADCAST TO UI
        String msg = AppStrings.isRu ? 'Заказ отменен или отклонен' : 'Buyurtma bekor qilindi yoki rad etildi';
        if (data['type'] == 'vacancy_closed') {
          msg = AppStrings.isRu ? 'Вакансия закрыта' : 'Vakansiya yopildi';
        }
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: '❌ Yaqin Go',
          body: msg,
          data: {'type': data['type'] == 'vacancy_closed' ? 'profile' : 'my_orders'},
        );
      } else if (data['type'] == 'chat_message') {
        _messageController.add(data); // BROADCAST TO UI
        
        // Suppress notification if user is ALREADY in this chat
        final orderId = data['order_id'] is int ? data['order_id'] : int.tryParse(data['order_id']?.toString() ?? '');
        if (orderId != null && orderId == NotificationService.activeChatOrderId) {
          debugPrint('SOCKET_SERVICE: Suppressing notification for active chat $orderId');
          return;
        }

        // Show notification for incoming chat messages
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: AppStrings.isRu 
            ? '💬 Сообщение от ${data['sender_name'] ?? 'пользователя'}'
            : '💬 ${data['sender_name'] ?? 'foydalanuvchi'} dan xabar',
          body: data['text'] ?? (AppStrings.isRu ? 'Новое сообщение' : 'Yangi xabar'),
          data: {'type': 'chat_${data['order_id']}'},
        );
      } else if (data['type'] == 'job_application') {
        _messageController.add(data);
        NotificationService.instance.showNotification(
          id: data['application_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: AppStrings.isRu ? '📋 Новая заявка на работу!' : '📋 Yangi ish arizasi!',
          body: AppStrings.isRu
            ? '${data['employer_name']} оставил заявку: ${data['description'] ?? ''}'
            : '${data['employer_name']} ariza qoldirdi: ${data['description'] ?? ''}',
          data: {'type': 'job_applications'},
        );
      } else if (data['type'] == 'job_application_status') {
        _messageController.add(data);
        final statusRu = data['status_text_ru'] ?? data['status'];
        final statusUz = data['status_text_uz'] ?? data['status'];
        NotificationService.instance.showNotification(
          id: data['application_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: AppStrings.isRu ? '📝 Статус заявки' : '📝 Ariza holati',
          body: AppStrings.isRu
            ? 'Мастер ${data['master_name']}: заявка $statusRu'
            : 'Usta ${data['master_name']}: ariza $statusUz',
          data: {'type': 'my_orders'},
        );
      } else if (data['type'] == 'hr_expiry_warning') {
        _messageController.add(data); // BROADCAST TO UI
        // Show dialog to HR employer asking if they want to extend
        final nav = YaqinApp.navigatorKey.currentState;
        if (nav != null) {
          final ctx = nav.overlay?.context;
          if (ctx != null) {
            final orderId = data['order_id'] is int ? data['order_id'] : int.tryParse(data['order_id']?.toString() ?? '');
            final subRu = data['subcategory_name_ru'] ?? '';
            final subUz = data['subcategory_name_uz'] ?? '';
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (dialogCtx) => AlertDialog(
                title: Text(AppStrings.isRu ? '⏰ Объявление закрывается!' : '⏰ E\'lon yopilmoqda!'),
                content: Text(
                  AppStrings.isRu
                    ? 'Вашей вакансии "${AppStrings.isRu ? subRu : subUz}" осталось 2 дня. Хотите продлить объявление ещё на 5 дней?'
                    : 'Sizning "${AppStrings.isRu ? subRu : subUz}" e\'loningizga 2 kun qoldi. E\'lonni yana 5 kunga uzaytirmoqchimisiz?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(AppStrings.isRu ? 'Нет' : 'Yo\'q'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      if (orderId != null) {
                        try {
                          await ApiService().extendHrAnnouncement(orderId);
                          NotificationService.instance.showNotification(
                            id: orderId,
                            title: AppStrings.isRu ? '✅ Объявление продлено' : '✅ E\'lon uzaytirildi',
                            body: AppStrings.isRu ? 'Объявление продлено ещё на 5 дней' : 'E\'lon yana 5 kunga uzaytirildi',
                            data: {'type': 'my_orders'},
                          );
                        } catch (e) {
                          debugPrint('SOCKET_SERVICE: Failed to extend HR announcement: $e');
                        }
                      }
                    },
                    child: Text(AppStrings.isRu ? 'Продлить на 5 дней' : 'Ha, 5 kun uzayt.'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Background: show system notification
          final orderId = data['order_id'] is int ? data['order_id'] : int.tryParse(data['order_id']?.toString() ?? '') ?? 0;
          NotificationService.instance.showNotification(
            id: orderId,
            title: AppStrings.isRu ? '⏰ Вакансия закрывается через 2 минуты!' : '⏰ Vakansiya 2 daqiqada yopiladi!',
            body: AppStrings.isRu ? 'Хотите продлить объявление ещё на 5 минут?' : 'E\'lonni yana 5 daqiqaga uzaytirmoqchimisiz?',
            data: {'type': 'my_orders'},
          );
        }
      } else if (data['type'] == 'vacancy_closed') {
        _messageController.add(data); // BROADCAST TO UI
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: AppStrings.isRu ? '🔒 Вакансия закрыта' : '🔒 Vakansiya yopildi',
          body: AppStrings.isRu
            ? 'HR-объявление «${data['subcategory_name_ru']}» закрыто'
            : 'HR e\'lon «${data['subcategory_name_uz']}» yopildi',
          data: {'type': 'my_orders'},
        );
      } else if (data['type'] == 'hr_accepted') {
        _messageController.add(data); // BROADCAST TO UI
        NotificationService.instance.showNotification(
          id: data['order_id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: AppStrings.isRu ? '🎉 Вы приняты!' : '🎉 Siz qabul qilindingiz!',
          body: AppStrings.isRu
            ? '${data['client_name']} принял вас на работу по вакансии «${data['subcategory_name_ru']}»'
            : '${data['client_name']} sizni «${data['subcategory_name_uz']}» vakansiyasiga qabul qildi',
          data: {'type': 'my_orders'},
        );
      }
    } catch (e) {
      debugPrint('SOCKET_SERVICE: Error parsing message: $e');
    }
  }

  void _showGlobalOverlay(dynamic order) {
    final nav = YaqinApp.navigatorKey.currentState;
    if (nav == null) return;
    
    OverlayState? overlayState = nav.overlay;
    if (overlayState == null) return;

    final theme = Theme.of(nav.context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: OrderNotificationOverlay(
                    order: order,
                    onTap: () {
                      overlayEntry.remove();
                      nav.pushNamed('/available-orders');
                    },
                    onClose: () => overlayEntry.remove(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlayState.insert(overlayEntry);
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add('ping');
          debugPrint('SOCKET_SERVICE: Sent ping');
        } catch (e) {
          debugPrint('SOCKET_SERVICE: Ping failed: $e');
        }
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void disconnect() {
    _stopPing();
    _channel?.sink.close();
    _isConnected = false;
    _connectedUserId = null;
  }
}
