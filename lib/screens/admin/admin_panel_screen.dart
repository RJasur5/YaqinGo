import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import 'admin_users_screen.dart';
import 'admin_orders_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final ApiService apiService;
  const AdminPanelScreen({super.key, required this.apiService});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await widget.apiService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching admin stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService().themeNotifier,
      builder: (context, mode, child) {
        final palette = AppTheme.getPalette(mode);

        return Container(
          decoration: BoxDecoration(gradient: palette.bgGradient),
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppStrings.isRu ? 'Админ-панель' : 'Admin paneli',
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    color: palette.textPrimary,
                    fontSize: 20
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: palette.textPrimary),
                    onPressed: _fetchStats,
                  ),
                ],
                bottom: TabBar(
                  tabs: [
                    Tab(text: AppStrings.isRu ? 'Пользователи' : 'Foydalanuvchilar'),
                    Tab(text: AppStrings.isRu ? 'Заказы' : 'Buyurtmalar'),
                  ],
                  indicatorColor: palette.primary,
                  labelColor: palette.textPrimary,
                  unselectedLabelColor: palette.textSecondary.withOpacity(0.5),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              body: Column(
                children: [
                  _buildStatsRow(palette),
                  Expanded(
                    child: TabBarView(
                      children: [
                        AdminUsersScreen(apiService: widget.apiService),
                        AdminOrdersScreen(apiService: widget.apiService),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(ThemePalette palette) {
    if (_isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
        ),
      );
    }

    if (_stats == null) return const SizedBox.shrink();

    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatCard(
            title: AppStrings.isRu ? 'Всего юзеров' : 'Jami foydalanuvchilar',
            value: '${_stats!['total_users']}',
            icon: Icons.people_outline,
            palette: palette,
          ),
          _StatCard(
            title: AppStrings.isRu ? 'Сейчас в сети' : 'Hozir onlayn',
            value: '${_stats!['online_users']}',
            icon: Icons.online_prediction,
            palette: palette,
            isHighlight: true,
          ),
          _StatCard(
            title: AppStrings.isRu ? 'Доступные заказы' : 'Mavjud buyurtmalar',
            value: '${_stats!['available_orders'] ?? 0}',
            icon: Icons.assignment_outlined,
            palette: palette,
          ),
          _StatCard(
            title: AppStrings.isRu ? 'Всего заказов' : 'Jami buyurtmalar',
            value: '${_stats!['total_orders']}',
            icon: Icons.shopping_basket_outlined,
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final ThemePalette palette;
  final bool isHighlight;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.palette,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? palette.primary : palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isHighlight ? Colors.white : palette.primary
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isHighlight ? Colors.white : palette.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isHighlight ? Colors.white.withOpacity(0.8) : palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
