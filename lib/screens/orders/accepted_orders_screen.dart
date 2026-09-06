import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/rating_stars.dart';
import '../../utils/date_utils.dart';
import '../../utils/formatters.dart';
import '../master_detail_screen.dart';
import '../client_profile_screen.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedOrdersScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  const AcceptedOrdersScreen({super.key, required this.apiService, required this.authService});

  @override
  State<AcceptedOrdersScreen> createState() => _AcceptedOrdersScreenState();
}

class _AcceptedOrdersScreenState extends State<AcceptedOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await widget.apiService.getMyOrders(type: 'master');
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load accepted orders';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isRu ? 'Принятые заказы' : 'Qabul qilingan buyurtmalar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.titleLarge?.color,
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : _orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        AppStrings.isRu ? 'У вас пока нет принятых заказов' : 'Hozircha qabul qilingan buyurtmalar yo\'q',
        style: const TextStyle(color: AppColors.textHint, fontSize: 16),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final theme = Theme.of(context);
    final subName = AppStrings.isRu ? order['subcategory_name_ru'] : order['subcategory_name_uz'];
    final status = order['status'];
    final date = DateTimeUtils.parseUtc(order['created_at']);
    final formattedDate = DateTimeUtils.formatFull(date);
    
    Color statusColor = Colors.orange;
    String statusText = AppStrings.isRu ? 'Открыто' : 'Ochiq';
    final bool isApp = order['is_application'] == true;
    
    if (status == 'accepted') {
      statusColor = Colors.blue;
      statusText = AppStrings.isRu ? 'Принято' : 'Qabul qilingan';
    } else if (status == 'accepted_hr') {
      statusColor = Colors.green;
      statusText = AppStrings.isRu ? 'Принято' : 'Qabul qilindi';  // Принято (вместо Завершено)
    } else if (status == 'completed') {
      statusColor = Colors.green;
      statusText = AppStrings.isRu ? 'Завершено' : 'Tugallangan';
    } else if (status == 'vacancy_closed') {
      statusColor = Colors.deepOrange;
      statusText = AppStrings.isRu ? 'Вакансия закрыта' : 'Vakansiya yopildi';  // Вместо Отказано
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = AppStrings.isRu ? 'Отказано' : 'Rad etilgan';
    } else if (status == 'pending') {
      statusColor = Colors.amber;
      statusText = AppStrings.isRu ? 'Ожидание' : 'Kutilmoqda';
    } else if (status == 'viewed') {
      statusColor = Colors.cyan;
      statusText = AppStrings.isRu ? 'Просмотрено' : 'Ko\'rilgan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApp ? statusColor.withOpacity(0.3) : theme.dividerColor.withOpacity(0.1),
          width: isApp ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isApp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppStrings.isRu ? 'ЗАЯВКА' : 'ARIZA',
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subName,
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _ExpandableDescription(description: order['description'], theme: theme, order: order),
            // Map link
            if (order['city'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: theme.textTheme.bodyMedium?.color, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order['city']}${order['district'] != null ? ', ${order['district']}' : ''}',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      String query;
                      if (order['lat'] != null && order['lon'] != null) {
                        query = '${order['lat']},${order['lon']}';
                      } else {
                        query = '${order['city']} ${order['district'] ?? ''}'.trim();
                      }
                      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
                      try {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch map: $e');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.isRu ? 'На карте' : 'Xaritada',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (order['price'] != null) ...[
              const SizedBox(height: 12),
              Text(
                '${PriceFormatter.format(order['price'])} ${AppStrings.sum}',
                style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor.withOpacity(0.1)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (order['client_id'] != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ClientProfileScreen(
                      clientId: order['client_id'],
                      apiService: widget.apiService,
                      overridePhone: order['client_phone'],
                    ),
                  ));
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_rounded, color: theme.hintColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppStrings.isRu ? 'Клиент:' : 'Mijoz:'} ${order['client_name']?.toString().capitalizeWords() ?? ''}',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (order['client_id'] != null)
                        Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
                    ],
                  ),
                  if (order['client_phone'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 4),
                      child: Text(
                        PriceFormatter.formatPhone(order['client_phone']),
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            if (status == 'accepted' || status == 'completed' || status == 'accepted_hr') ...[
              const SizedBox(height: 16),
              if (order['is_client_reviewed'] == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.isRu ? 'Вы уже оценили клиента' : 'Mijoz baholangan',
                      style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else ...[
                GradientButton(
                  text: AppStrings.isRu ? 'Чат с клиентом' : 'Mijoz bilan chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          order: order,
                          apiService: widget.apiService,
                          currentUserId: widget.authService.currentUser?.id ?? 0,
                        ),
                      ),
                    );
                  },
                ),
                if (status == 'completed') ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    text: AppStrings.isRu ? 'Оценить клиента' : 'Mijozni baholash',
                    onPressed: () => _showRateClientDialog(order),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showRateClientDialog(dynamic order) {
    final theme = Theme.of(context);
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(AppStrings.isRu ? 'Оценить клиента' : 'Mijozni baholash', style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),
              RatingInput(
                value: rating,
                onChanged: (v) => setModalState(() => rating = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: AppStrings.isRu ? 'Ваш отзыв о клиенте...' : 'Mijoz haqida fikringiz...',
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: AppStrings.save,
                onPressed: () async {
                  try {
                    await widget.apiService.rateClient(order['id'], rating, commentController.text);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadOrders();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final String description;
  final ThemeData theme;
  final Map<String, dynamic>? order;
  const _ExpandableDescription({required this.description, required this.theme, this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.isRu ? 'Подробнее →' : 'Batafsil →',
              style: TextStyle(color: theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailSheet(BuildContext context) {
    final o = order;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                AppStrings.isRu ? 'Подробности заказа' : 'Buyurtma tafsilotlari',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                AppStrings.isRu ? 'Описание' : 'Tavsif',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor),
              ),
              const SizedBox(height: 6),
              Text(description, style: TextStyle(fontSize: 15, height: 1.6, color: theme.textTheme.bodyLarge?.color)),
              if (o != null) ...[
                if (o['price'] != null) ...[
                  const SizedBox(height: 16),
                  _infoRow(Icons.payments_outlined, AppStrings.isRu ? 'Цена' : 'Narx', '${PriceFormatter.format(o['price'])} ${AppStrings.sum}'),
                ],
                if (o['city'] != null) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final String query;
                      if (o['lat'] != null && o['lon'] != null) {
                        query = '${o['lat']},${o['lon']}';
                      } else {
                        query = '${o['city']} ${o['district'] ?? ''}'.trim();
                      }
                      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
                      try {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Map launch error: $e');
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${o['city']}${o['district'] != null ? ', ${o['district']}' : ''}',
                            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(AppStrings.isRu ? 'Карта' : 'Xarita',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (o['include_lunch'] == true) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.restaurant_rounded, AppStrings.isRu ? 'Обед' : 'Tushlik', AppStrings.isRu ? 'Включён' : 'Kiritilgan'),
                ],
                if (o['include_taxi'] == true) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.local_taxi_rounded, AppStrings.isRu ? 'Проезд' : 'Yo\'l', AppStrings.isRu ? 'Оплачивается' : 'To\'lanadi'),
                ],
                if (o['is_company'] == true) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.groups_rounded, 'HR', AppStrings.isRu ? 'Набор персонала' : 'Xodimlar yollash'),
                ],
                if (o['client_name'] != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.person_outline, AppStrings.isRu ? 'Клиент' : 'Mijoz', o['client_name']?.toString().capitalizeWords() ?? ''),
                ],
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.isRu ? 'Закрыть' : 'Yopish', style: TextStyle(color: theme.primaryColor, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.hintColor),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: theme.hintColor, fontSize: 13)),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color))),
      ],
    );
  }
}
