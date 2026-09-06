import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../models/order.dart';
import '../../widgets/glass_container.dart';

class AdminOrdersScreen extends StatefulWidget {
  final ApiService apiService;
  const AdminOrdersScreen({super.key, required this.apiService});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<OrderResponse> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await widget.apiService.getAdminOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteOrder(OrderResponse order) async {
    final palette = AppTheme.currentPalette(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        surfaceTintColor: palette.primary,
        title: Text(
          AppStrings.isRu ? 'Удалить заказ?' : 'Buyurtmani o\'chirish?', 
          style: TextStyle(color: palette.textPrimary)
        ),
        content: Text(
          '${AppStrings.isRu ? 'Вы уверены, что хотите удалить заказ №' : 'Buyurtmani o\'chirishni xohlaysizmi №'}${order.id}?',
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppStrings.isRu ? 'Удалить' : 'O\'chirish', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.deleteOrder(order.id);
        _fetchOrders();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService().themeNotifier,
      builder: (context, mode, child) {
        final palette = AppTheme.getPalette(mode);

        if (_isLoading) return Center(child: CircularProgressIndicator(color: palette.primary));

        if (_orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_rounded, size: 80, color: palette.textSecondary.withOpacity(0.2)),
                const SizedBox(height: 24),
                Text(
                  AppStrings.isRu ? 'Заказов нет' : 'Buyurtmalar yo\'q',
                  style: TextStyle(color: palette.textSecondary, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchOrders,
          color: palette.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: ListTile(
                    title: Text(
                      order.subcategoryName(AppStrings.lang),
                      style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          order.description, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(color: palette.textSecondary)
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_rounded, size: 14, color: palette.textHint),
                            const SizedBox(width: 4),
                            Text(
                              '${AppStrings.isRu ? 'Клиент: ' : 'Mijoz: '}${order.clientName}',
                              style: TextStyle(color: palette.textHint, fontSize: 12),
                            ),
                          ],
                        ),
                        if (order.masterName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.handyman_rounded, size: 14, color: palette.primary.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppStrings.isRu ? 'Мастер: ' : 'Usta: '}${order.masterName}',
                                  style: TextStyle(color: palette.primary.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _deleteOrder(order),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
