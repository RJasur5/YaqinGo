import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/local_notifications_store.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<LocalNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifs = await LocalNotificationsStore.getNotifications();
    setState(() {
      _notifications = notifs;
      _isLoading = false;
    });
    // Mark as read after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      LocalNotificationsStore.markAllAsRead();
    });
  }

  void _clearNotifications() async {
    await LocalNotificationsStore.clearAll();
    setState(() {
      _notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.isRu ? 'Уведомления' : 'Bildirishnomalar'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppStrings.isRu ? 'Очистить все?' : 'Barchasini tozalash?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppStrings.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearNotifications();
                        },
                        child: Text(AppStrings.isRu ? 'Очистить' : 'Tozalash', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: theme.dividerColor),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.isRu ? 'Нет уведомлений' : 'Bildirishnomalar yo\'q',
                        style: TextStyle(color: theme.hintColor, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return GestureDetector(
                      onTap: () {
                        if (notif.data.isNotEmpty) {
                          NotificationService.instance.handlePayload(notif.data);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.isRead ? theme.cardColor : theme.cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: notif.isRead ? theme.dividerColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.5),
                            width: notif.isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_active_rounded, color: theme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 15,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.body,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(notif.timestamp),
                                    style: TextStyle(
                                      color: theme.hintColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${AppStrings.isRu ? "дн. назад" : "kun oldin"}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}
