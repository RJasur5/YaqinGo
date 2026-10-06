import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import 'create_order_screen.dart';
import '../../widgets/rating_stars.dart';
import '../../utils/date_utils.dart';
import '../../utils/formatters.dart';
import '../master_detail_screen.dart';
import '../client_profile_screen.dart';
import 'chat_screen.dart';
import 'dart:async';
import '../../services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  const MyOrdersScreen({super.key, required this.apiService, required this.authService});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _socketSubscription;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupSocketListener();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _setupSocketListener() {
    _socketSubscription = SocketService().messageStream.listen((data) {
      if (!mounted) return;
      if (data['type'] == 'order_accepted' || 
          data['type'] == 'order_completed' || 
          data['type'] == 'order_rejected' || 
          data['type'] == 'order_cancelled' ||
          data['type'] == 'vacancy_closed' ||
          data['type'] == 'hr_accepted' ||
          data['type'] == 'hr_expiry_warning') {
        _loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final role = widget.authService.currentUser?.role;
      final orders = await widget.apiService.getMyOrders(type: 'client');
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load orders';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirmed = await _showConfirmDialog(
      AppStrings.isRu ? 'Отмена заказа' : 'Buyurtmani bekor qilish',
      AppStrings.isRu ? 'Вы уверены, что хотите отменить этот заказ?' : 'Haqiqatan ham ushbu buyurtmani bekor qilmoqchimisiz?',
    );
    if (!confirmed) return;

    try {
      await widget.apiService.cancelOrder(orderId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _withdrawApplication(int applicationId) async {
    final confirmed = await _showConfirmDialog(
      AppStrings.isRu ? 'Отозвать заявку' : 'Arizani qaytarib olish',
      AppStrings.isRu ? 'Вы уверены, что хотите отозвать эту заявку?' : 'Haqiqatan ham ushbu arizani qaytarib olmoqchimisiz?',
    );
    if (!confirmed) return;

    try {
      await widget.apiService.withdrawJobApplication(applicationId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancelOthers(int orderId) async {
    final confirmed = await _showConfirmDialog(
      AppStrings.isRu ? 'Отменить всем' : 'Barchasini bekor qilish',
      AppStrings.isRu ? 'Отменить все отклики на это HR-объявление? Все мастера получат уведомление об отмене.' : 'Barcha javoblarni bekor qilasizmi? Barcha ustalarga bildirishnoma yuboriladi.',
    );
    if (!confirmed) return;

    try {
      await widget.apiService.cancelOthers(orderId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectMaster(int orderId) async {
    final confirmed = await _showConfirmDialog(
      AppStrings.reject,
      AppStrings.isRu ? 'Вы уверены, что хотите отклонить этого мастера? Статус заказа станет "Отказано".' : 'Haqiqatan ham ushbu ustani rad etmoqchimisiz? Buyurtma holati "Rad etildi" ga o\'zgaradi.',
    );
    if (!confirmed) return;

    try {
      await widget.apiService.rejectMaster(orderId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _hrAcceptMaster(int orderId) async {
    final confirmed = await _showConfirmDialog(
      AppStrings.isRu ? 'Принять мастера' : 'Ustani qabul qilish',
      AppStrings.isRu ? 'Вы уверены, что хотите принять этого кандидата?' : 'Haqiqatan ham ushbu nomzodni qabul qilmoqchimisiz?',
    );
    if (!confirmed) return;

    try {
      await widget.apiService.hrAcceptMaster(orderId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.ok, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppStrings.isRu ? 'Мои заказы' : 'Mening buyurtmalarim'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.bodyLarge?.color,
          actions: [
            IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 100),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateOrderScreen(
                  apiService: widget.apiService,
                  authService: widget.authService,
                ),
              ),
            ).then((res) {
              if (res == true) _loadOrders();
            });
          },
          label: Text(AppStrings.isRu ? 'Подать объявление' : 'E\'lon berish'),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        AppStrings.isRu ? 'У вас пока нет заказов' : 'Hozircha buyurtmalaringiz yo\'q',
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
    
    final String myRole = order['my_role'] ?? 'employer';
    final bool isEmployer = myRole == 'employer';
    final bool isWorker = myRole == 'worker';
    
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
    } else if (status == 'pending') {
      statusColor = Colors.amber;
      statusText = AppStrings.applicationPending;
    } else if (status == 'viewed') {
      statusColor = Colors.cyan;
      statusText = AppStrings.applicationViewed;
    } else if (status == 'vacancy_closed') {
      statusColor = Colors.deepOrange;
      statusText = AppStrings.isRu ? 'Вакансия закрыта' : 'Vakansiya yopildi';  // Вакансия закрыта (вместо Отказано)
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = AppStrings.applicationRejected;
    } else if (status == 'cancelled') {
      statusColor = Colors.grey;
      statusText = AppStrings.isRu ? 'Вы отменили заказ' : 'Siz bekor qildingiz';
    }

    // Role badge text
    final String roleBadge = isEmployer
        ? (AppStrings.isRu ? 'Ваш заказ' : 'Sizning buyurtma')
        : (AppStrings.isRu ? 'Вы исполнитель' : 'Siz ijrochi');
    final Color roleBadgeColor = isEmployer ? Colors.deepPurple : Colors.teal;
    final bool isMyOrderCompany = order['is_company'] == true &&
        order['company_name'] != null &&
        order['company_name'].toString().trim().isNotEmpty;
    final int myReqWorkers = (order['required_workers'] is int)
        ? (order['required_workers'] as int)
        : (int.tryParse(order['required_workers']?.toString() ?? '1') ?? 1);

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
            // Role badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleBadgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEmployer ? Icons.work_outline_rounded : Icons.construction_rounded,
                        size: 12,
                        color: roleBadgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        roleBadge,
                        style: TextStyle(color: roleBadgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (isApp) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppStrings.isRu ? 'ЗАЯВКА' : 'ARIZA',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            if (isMyOrderCompany || (order['branch_name'] != null && order['branch_name'].toString().isNotEmpty)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isMyOrderCompany)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.isRu ? 'КОМПАНИЯ' : 'KOMPANIYA',
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  if (order['branch_name'] != null && order['branch_name'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_mall_directory_rounded, size: 12, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            order['branch_name'].toString(),
                            style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else if (myReqWorkers > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.isRu ? 'ТРЕБУЕТСЯ: $myReqWorkers ЧЕЛ.' : 'KERAK: $myReqWorkers KISHI',
                      style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
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
            if (order['price'] != null) ...[
              const SizedBox(height: 12),
              Text(
                '${PriceFormatter.format(order['price'])} ${AppStrings.sum}',
                style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            _buildOptionsRow(order),
            // Show the OTHER participant
            if (isEmployer && order['master_name'] != null && !(order['is_company'] == true && status == 'open')) ...[
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor.withOpacity(0.1)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (order['master_id'] != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MasterDetailScreen(
                        apiService: widget.apiService,
                        masterId: order['master_id'],
                      )
                    ));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.construction_rounded, color: theme.hintColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.isRu ? 'Мастер:' : 'Usta:'} ${order['master_name']?.toString().capitalizeWords() ?? ''}',
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order['master_id'] != null)
                          Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
                      ],
                    ),
                    if (order['master_phone'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4),
                        child: Text(
                          PriceFormatter.formatPhone(order['master_phone']),
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (isWorker && order['client_name'] != null) ...[
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
                            '${AppStrings.isRu ? 'Заказчик:' : 'Buyurtmachi:'} ${order['client_name']?.toString().capitalizeWords() ?? ''}',
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
            ],
            if (status == 'accepted' || status == 'completed' || status == 'accepted_hr') ...[
              const SizedBox(height: 16),
              GradientButton(
                text: isEmployer
                    ? (AppStrings.isRu ? 'Чат с мастером' : 'Usta bilan chat')
                    : (AppStrings.isRu ? 'Чат с заказчиком' : 'Buyurtmachi bilan chat'),
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
              const SizedBox(height: 12),
            ],
            // Cancel/Withdraw buttons
            if (isEmployer) ...[
              if (isApp && (status == 'pending' || status == 'viewed')) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _withdrawApplication(order['id']),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(AppStrings.withdraw),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ] else if (!isApp && (status == 'accepted' || status == 'pending')) ...[
                if (order['is_company'] == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _hrAcceptMaster(order['id']),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(AppStrings.isRu ? 'Принять' : 'Qabul qilish'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 45),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectMaster(order['id']),
                          icon: const Icon(Icons.person_remove_rounded, size: 18),
                          label: Text(AppStrings.reject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else if (!isApp && status == 'open') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _cancelOrder(order['id']),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(AppStrings.cancelOrder),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ],
            // Review buttons
            if (status == 'completed') ...[
              if (isEmployer && order['master_id'] != null) ...[
                if (order['is_master_reviewed'] == true)
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
                        AppStrings.isRu ? 'Вы уже оценили мастера' : 'Usta baholangan',
                        style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  GradientButton(
                    text: AppStrings.isRu ? 'Оценить мастера' : 'Ustani baholash',
                    onPressed: () => _showRateMasterDialog(context, order),
                  ),
              ],
              if (isWorker) ...[
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
                else
                  GradientButton(
                    text: AppStrings.isRu ? 'Оценить клиента' : 'Mijozni baholash',
                    onPressed: () => _showRateClientDialog(context, order),
                  ),
              ],
            ],
            if (isEmployer && !isApp)
              _buildOrderStatsCard(order, theme),
          ],
        ),
      ),
    );
  }


  Widget _buildOrderStatsCard(dynamic order, ThemeData theme) {
    final int views = (order['views_count'] is int)
        ? order['views_count']
        : (int.tryParse(order['views_count']?.toString() ?? '0') ?? 0);
    final int clicks = (order['clicks_count'] is int)
        ? order['clicks_count']
        : (int.tryParse(order['clicks_count']?.toString() ?? '0') ?? 0);
    final int calls = (order['calls_count'] is int)
        ? order['calls_count']
        : (int.tryParse(order['calls_count']?.toString() ?? '0') ?? 0);
    final int applicants = (order['applicants_count'] is int)
        ? order['applicants_count']
        : (int.tryParse(order['applicants_count']?.toString() ?? '0') ?? 0);
    final bool isTelegramOnly = (order['contact_telegram'] != null && order['contact_telegram'].toString().trim().isNotEmpty) &&
        (order['contact_phone'] == null || order['contact_phone'].toString().trim().isEmpty);
    final String callLabel = isTelegramOnly
        ? (AppStrings.isRu ? 'переходов' : 'o\'tishlar')
        : (AppStrings.isRu ? 'звонков' : 'qo\'ng\'iroq');
    final IconData callIcon = isTelegramOnly ? Icons.send_rounded : Icons.phone_outlined;
    final Color callColor = isTelegramOnly ? const Color(0xFF229ED9) : const Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactStat(Icons.visibility_outlined, const Color(0xFF2563EB), '$views', AppStrings.isRu ? 'увидели' : 'ko\'rildi', theme),
          Container(width: 1, height: 16, color: theme.dividerColor.withValues(alpha: 0.2)),
          _buildCompactStat(Icons.touch_app_outlined, const Color(0xFF7C3AED), '$clicks', AppStrings.isRu ? 'кликнули' : 'ochildi', theme),
          Container(width: 1, height: 16, color: theme.dividerColor.withValues(alpha: 0.2)),
          _buildCompactStat(callIcon, callColor, '$calls', callLabel, theme),
        ],
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, Color color, String value, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }


  void _showRateMasterDialog(BuildContext context, dynamic order) {
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
              Text(AppStrings.writeReview, style: theme.textTheme.titleMedium),
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
                  hintText: AppStrings.isRu ? 'Ваш комментарий...' : 'Sharhingiz...',
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: AppStrings.save,
                onPressed: () async {
                  try {
                    await widget.apiService.rateMasterByOrder(order['id'], rating, commentController.text);
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

  void _showRateClientDialog(BuildContext context, dynamic order) {
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
              Text(
                AppStrings.isRu ? 'Оценить клиента' : 'Mijozni baholash',
                style: theme.textTheme.titleMedium,
              ),
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
                  hintText: AppStrings.isRu ? 'Ваш комментарий...' : 'Sharhingiz...',
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



  Widget _buildOptionsRow(dynamic order) {
    final theme = Theme.of(context);
    final includeLunch = order['include_lunch'] == true;
    final includeTaxi = order['include_taxi'] == true;

    if (!includeLunch && !includeTaxi) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: [
        if (includeLunch)
          _buildOptionBadge(
            icon: Icons.restaurant_rounded,
            label: AppStrings.includeLunch,
            color: Colors.orange,
          ),
        if (includeTaxi)
          _buildOptionBadge(
            icon: Icons.local_taxi_rounded,
            label: AppStrings.includeTaxi,
            color: Colors.blue,
          ),
      ],
    );
  }

  Widget _buildOptionBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class RatingInput extends StatelessWidget {
  final int value;
  final Function(int) onChanged;

  const RatingInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < value ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 40,
          ),
          onPressed: () => onChanged(index + 1),
        );
      }),
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
