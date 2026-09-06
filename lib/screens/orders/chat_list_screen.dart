import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/date_utils.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';
import '../../config/localization.dart';
import '../../services/socket_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  final ApiService apiService;
  final int currentUserId;

  const ChatListScreen({
    super.key, 
    required this.apiService, 
    required this.currentUserId
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _socketSub = SocketService().messageStream.listen((event) {
      if (event['type'] == 'chat_message' || 
          event['type'] == 'order_accepted' || 
          event['type'] == 'order_completed' || 
          event['type'] == 'order_rejected' || 
          event['type'] == 'order_cancelled' ||
          event['type'] == 'job_application_status') {
        _loadChats();
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await widget.apiService.getChatList();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final date = DateTimeUtils.parseUtc(timeStr);
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return DateFormat('HH:mm').format(date);
      }
      return DateFormat('dd.MM').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.chats, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _chats.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadChats,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _chats.length,
                      separatorBuilder: (_, __) => Divider(
                        indent: 80, 
                        height: 1, 
                        color: Theme.of(context).dividerColor.withOpacity(0.1)
                      ),
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return _buildChatItem(chat);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(AppStrings.noChats, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChatItem(dynamic chat) {
    final theme = Theme.of(context);
    final hasAvatar = chat['other_user_avatar'] != null;
    final lastMsg = chat['last_message'] ?? AppStrings.startConversation;
    final unreadCount = chat['unread_count'] ?? 0;
    
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              order: {
                'id': chat['order_id'], 
                'client_id': chat['client_id'],
                'master_id': chat['master_id'],
                'subcategory_name_ru': chat['subcategory_name_ru'],
                'subcategory_name_uz': chat['subcategory_name_uz'],
                'other_name': chat['other_user_name'],
                'other_avatar': chat['other_user_avatar'],
                'other_user_id': chat['other_user_id'],
                'other_user_role': chat['other_user_role'],
                'other_master_id': chat['other_master_id'],
              }, 
              apiService: widget.apiService,
              currentUserId: widget.currentUserId,
            ),
          ),
        ).then((_) => _loadChats());
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: hasAvatar 
            ? NetworkImage(
                chat['other_user_avatar'].toString().startsWith('http')
                    ? chat['other_user_avatar']
                    : '${ApiConfig.baseUrl}${chat['other_user_avatar']}'
              )
            : null,
        child: !hasAvatar 
            ? Text(chat['other_user_name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)) 
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat['other_user_name'], 
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold, 
                fontSize: 16,
                color: unreadCount > 0 ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
              )
            )
          ),
          Text(
            _formatTime(chat['last_message_time']), 
            style: TextStyle(
              color: unreadCount > 0 ? theme.primaryColor : theme.hintColor, 
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            )
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
