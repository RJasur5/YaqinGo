import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../widgets/master_card.dart';
import '../utils/formatters.dart';
import 'master_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final ApiService apiService;
  const FavoritesScreen({super.key, required this.apiService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MasterModel> _favoriteMasters = [];
  List<Map<String, dynamic>> _favoriteOrders = [];
  bool _isLoadingMasters = true;
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadMasters();
    _loadOrders();
  }

  Future<void> _loadMasters() async {
    try {
      final favs = await widget.apiService.getFavorites();
      if (mounted) setState(() { _favoriteMasters = favs; _isLoadingMasters = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMasters = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await widget.apiService.getFavoriteOrders();
      if (mounted) setState(() { _favoriteOrders = orders; _isLoadingOrders = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.titleLarge?.color,
          title: Text(
            isRu ? '⭐ Избранные' : '⭐ Sevimlilar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: theme.hintColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(
                text: isRu
                    ? 'Специалисты (${_favoriteMasters.length})'
                    : 'Mutaxassislar (${_favoriteMasters.length})',
              ),
              Tab(
                text: isRu
                    ? 'Вакансии (${_favoriteOrders.length})'
                    : 'Vakansiyalar (${_favoriteOrders.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMastersTab(theme, isRu),
            _buildOrdersTab(theme, isRu),
          ],
        ),
      ),
    );
  }

  Widget _buildMastersTab(ThemeData theme, bool isRu) {
    if (_isLoadingMasters) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_favoriteMasters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 70, color: theme.hintColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              isRu ? 'Нет избранных специалистов' : 'Sevimli mutaxassislar yo\'q',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isRu
                  ? 'Добавляйте мастеров в избранное из их профиля'
                  : 'Mutaxassislarni o\'z profilidan sevimlilarga qo\'shing',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMasters,
      color: theme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        itemCount: _favoriteMasters.length,
        itemBuilder: (context, index) {
          final master = _favoriteMasters[index];
          return MasterCard(
            master: master,
            isFavorite: true,
            onFavorite: () async {
              await widget.apiService.toggleFavorite(master.id);
              _loadMasters();
            },
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MasterDetailScreen(
                    apiService: widget.apiService,
                    masterId: master.id,
                  ),
                ),
              );
              _loadMasters();
            },
          );
        },
      ),
    );
  }

  Widget _buildOrdersTab(ThemeData theme, bool isRu) {
    if (_isLoadingOrders) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_favoriteOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline_rounded, size: 70, color: theme.hintColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              isRu ? 'Нет избранных вакансий' : 'Sevimli vakansiyalar yo\'q',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isRu
                  ? 'Нажмите сердечко ❤️ рядом с именем работодателя в ленте'
                  : 'Lentada ish beruvchi ismining yonidagi ❤️ tugmasini bosing',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: theme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        itemCount: _favoriteOrders.length,
        itemBuilder: (context, index) {
          final order = _favoriteOrders[index];
          final contactPhone = (order['contact_phone'] ?? '').toString().trim();
          final phoneToUse = contactPhone.isNotEmpty ? contactPhone : (order['client_phone'] ?? '').toString();
          final rawPhone = phoneToUse.replaceAll(RegExp(r'[^\d+]'), '');
          final telegram = (order['contact_telegram'] ?? '').toString().trim();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: subcategory name + favorite badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order['subcategory_name_ru'] ?? order['subcategory_name'] ?? 'Вакансия',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final orderId = order['id'];
                        if (orderId != null) {
                          setState(() {
                            _favoriteOrders.removeAt(index);
                          });
                          try {
                            await widget.apiService.toggleFavoriteOrder(orderId);
                          } catch (_) {}
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isRu ? 'Вакансия удалена из избранных' : 'Vakansiya sevimlilardan o\'chirildi',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.grey.shade800,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 16, color: Colors.red),
                            const SizedBox(width: 5),
                            Text(
                              isRu ? 'В избранном' : 'Sevimlilarda',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Location
                Text(
                  '${order['city'] ?? ''}${order['district'] != null ? ', ' + order['district'] : ''}',
                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  order['description'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, height: 1.4, color: theme.textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 12),
                // Employer row
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      order['client_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (order['price'] != null)
                      Text(
                        '${PriceFormatter.format(order['price'])} ${AppStrings.sum}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Contact button
                if (telegram.isNotEmpty)
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF229ED9),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        widget.apiService.trackOrderCall(order['id']);
                        String clean = telegram.replaceAll('@', '').trim();
                        final uri = Uri.parse(clean.startsWith('http') ? clean : 'https://t.me/$clean');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Telegram',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (rawPhone.isNotEmpty)
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        widget.apiService.trackOrderCall(order['id']);
                        final uri = Uri.parse('tel:$rawPhone');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isRu ? 'Позвонить' : 'Qo\'ng\'iroq qilish',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
