import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../models/category.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/theme_service.dart';
import '../widgets/master_card.dart';
import '../widgets/glass_container.dart';
import 'masters_list_screen.dart';
import 'master_detail_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';
import 'orders/available_orders_screen.dart';
import 'orders/my_orders_screen.dart';
import 'orders/create_order_screen.dart';
import 'orders/accepted_orders_screen.dart';
import 'orders/chat_list_screen.dart';
import 'notifications_screen.dart';
import '../services/local_notifications_store.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  const HomeScreen({super.key, required this.apiService, required this.authService});

  /// Static callback for notification navigation to switch tabs from outside
  static void Function(int)? switchToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 3;
  List<CategoryModel> _categories = [];
  List<MasterModel> _topMasters = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final _searchController = TextEditingController();
  bool _isCategoriesExpanded = false;
  
  int? _lastOrderId;
  bool _hasNewOrderBadge = false;
  MasterModel? _masterProfile;
  Map<int, String> _myOrderStatuses = {};
  int _chatRefreshCounter = 0;
  int _ordersRefreshCounter = 0;
  int _totalUnreadCount = 0;
  StreamSubscription? _socketSub;
  int? _initialSearchCategoryId;
  bool _hideBottomNav = false;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
    _loadData();
    _checkUser();
    
    // Register the static tab-switch callback for notification navigation
    HomeScreen.switchToTab = (int tabIndex) {
      if (mounted) {
        setState(() => _currentTab = tabIndex);
      }
    };
    
    // Fallback: check for notifications again after Home is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingNotifications();
    });
  }

  void _processPendingNotifications() async {
    // Mark app as ready since HomeScreen is now mounted
    NotificationService.isReadyForNavigation = true;
    
    // Small delay to allow transition animations to finish
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      NotificationService.instance.processPendingNavigation();
    }
  }

  void _checkUser() {
    final user = widget.authService.currentUser;
    if (user != null) {
      // Connect to WebSocket for instant notifications
      SocketService().connect(user.id);
      
      // LISTEN FOR MESSAGES (Chat only, orders handled globally)
      _loadData();
      _loadUnreadCount();

      _socketSub = SocketService().messageStream.listen((event) {
        if (!mounted) return;
        if (event['type'] == 'chat_message') {
          setState(() {
            _totalUnreadCount++;
          });
        } else if (event['type'] == 'new_order') {
          // If I am a master, show the red badge on orders tab
          if (widget.authService.currentUser?.role == 'master') {
            setState(() {
              _hasNewOrderBadge = true;
            });
          }
        }
      });

      if (user.role == 'master') {
        widget.apiService.getMyMasterProfile().then((p) {
          setState(() {
            _masterProfile = p;
          });
          // REGISTER TO SOCKET SERVICE FOR GLOBAL OVERLAYS
          SocketService().setMasterProfile(p);
        }).catchError((e) {
          debugPrint('Error loading master profile: $e');
        });
      }
    }
  }

  bool _isOrderForMe(dynamic order) {
    if (_masterProfile == null) return false;
    
    // Only notify if specialization matches
    // Bypass for test orders (to allow developers to see the UI)
    if (order['order_id'] == 100500 || order['order_id'] == 999) return true;
    
    if (order['subcategory_id'] != _masterProfile!.subcategoryId) return false;
    
    final orderDistrict = (order['district'] ?? '').toString().toLowerCase();
    
    // If client didn't specify a district, it's for everyone in the city
    if (orderDistrict.isEmpty) return true;
    
    final masterAddr = (_masterProfile!.address ?? '').toLowerCase();
    
    // Check if order district is mentioned in master's address
    return masterAddr.contains(orderDistrict);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final chats = await widget.apiService.getChatList();
      int unread = 0;
      for (var chat in chats) {
        unread += (chat['unread_count'] as int? ?? 0);
      }
      if (mounted) {
        setState(() => _totalUnreadCount = unread);
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }


  void _showNewOrderNotification(dynamic order) {
    // This localized method is now handled globally by SocketService
  }

  void _showNewOrderDialog(dynamic order) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.newOrderNotification,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order['subcategory_name_ru'] ?? order['title'] ?? '',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (order['price'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${order['price']} сум',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            if (order['district'] != null)
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.textHint, size: 16),
                  const SizedBox(width: 4),
                  Text(order['district'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              order['description'] ?? '',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                print("DEBUG: Switching to tab 3 (Orders) from dialog");
                _currentTab = 3;
                _ordersRefreshCounter++;
                _hasNewOrderBadge = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppStrings.view),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final cats = await widget.apiService.getCategories();
      final masters = await widget.apiService.getMasters(sortBy: 'rating', limit: 10);
      if (mounted) {
        setState(() {
          _categories = cats;
          _topMasters = masters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCategoryName(String name) {
    if (name.toLowerCase() == 'юриспруденция') {
      return 'Юриспруден\nция';
    } else if (name.toLowerCase() == 'недвижимость') {
      return 'Недвижи\nмость';
    } else if (name.toLowerCase() == 'строительство') {
      return 'Строитель\nство';
    } else if (name.toLowerCase() == 'образование') {
      return 'Образова\nние';
    }
    return name;
  }

  IconData _getIconForName(String name) {
    final icons = {
      'construction': Icons.construction_rounded,
      'medical_services': Icons.medical_services_rounded,
      'school': Icons.school_rounded,
      'directions_car': Icons.directions_car_rounded,
      'computer': Icons.computer_rounded,
      'spa': Icons.spa_rounded,
      'gavel': Icons.gavel_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'cleaning_services': Icons.cleaning_services_rounded,
      'palette': Icons.palette_rounded,
      'account_balance': Icons.account_balance_rounded,
      'camera_alt': Icons.camera_alt_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'color_lens': Icons.color_lens_rounded,
      'restaurant': Icons.restaurant_rounded,
      'agriculture': Icons.agriculture_rounded,
      'apartment': Icons.apartment_rounded,
      'campaign': Icons.campaign_rounded,
      'flight_takeoff': Icons.flight_takeoff_rounded,
      'house_siding': Icons.house_siding_rounded,
    };
    return icons[name] ?? Icons.category_rounded;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final isMaster = user?.role == 'master';

    final pages = [
      _buildHomePage(isMaster),
      MastersListScreen(
        apiService: widget.apiService, 
        authService: widget.authService,
        categories: _categories,
        initialCategoryId: _initialSearchCategoryId,
        onFullscreenChanged: (isFullscreen) {
          setState(() => _hideBottomNav = isFullscreen);
        },
        key: ValueKey('search_${_initialSearchCategoryId}_${user?.latitude}_${user?.longitude}'),
      ),
      user != null 
          ? ChatListScreen(apiService: widget.apiService, currentUserId: user.id, key: ValueKey('chats_$_chatRefreshCounter'))
          : const Center(child: CircularProgressIndicator()),
      AvailableOrdersScreen(
        apiService: widget.apiService, 
        authService: widget.authService,
        categories: _categories, 
        onFullscreenChanged: (isFullscreen) {
          setState(() => _hideBottomNav = isFullscreen);
        },
        key: ValueKey('available_${_ordersRefreshCounter}_${user?.latitude}_${user?.longitude}'),
      ),
      ProfileScreen(authService: widget.authService, apiService: widget.apiService),
    ];

    return Scaffold(
      body: pages[_currentTab],
      bottomNavigationBar: _hideBottomNav ? null : Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            setState(() {
              _currentTab = i;
              if (i != 1) _initialSearchCategoryId = null; // Reset filter when navigating manually to other tabs
              if (i == 2) {
                _chatRefreshCounter++;
                _loadUnreadCount();
              }
              if (i == 3) _hasNewOrderBadge = false;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              label: AppStrings.search,
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded),
                  if (_totalUnreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          _totalUnreadCount > 9 ? '9+' : _totalUnreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: AppStrings.isRu ? "Чаты" : "Chatlar",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.assignment_rounded),
                  if (_hasNewOrderBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                ],
              ),
              label: AppStrings.orders,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage(bool isMaster) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(child: _buildHeader(isMaster)),
                    // Search bar
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    // Categories
                    SliverToBoxAdapter(child: _buildCategoriesSection()),
                    // Top Masters
                    SliverToBoxAdapter(child: _buildTopMastersSection()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isMaster) {
    final theme = Theme.of(context);
    final user = widget.authService.currentUser;
    final name = (user?.name ?? 'Пользователь').split(' ')[0].capitalizeWords();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.isRu ? "Привет" : "Salom"}, $name! 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.appSlogan,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ).then((_) => setState(() {}));
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: FutureBuilder<int>(
                    future: LocalNotificationsStore.getUnreadCount(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, color: theme.textTheme.bodyMedium?.color, size: 22),
                          if (unreadCount > 0)
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(authService: widget.authService),
                  ),
                ).then((_) => setState(() {})),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Icon(Icons.settings_rounded, color: theme.textTheme.bodyMedium?.color, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 12),
              Text(
                AppStrings.searchHint,
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text(
                AppStrings.categories,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isCategoriesExpanded = !_isCategoriesExpanded),
                child: Text(
                  _isCategoriesExpanded 
                      ? (AppStrings.isRu ? 'Скрыть' : 'Yashirish')
                      : (AppStrings.isRu ? 'Открыть' : 'Ochish'),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              mainAxisExtent: 125, // Increased height to prevent overlap
            ),
            itemCount: _isCategoriesExpanded ? _categories.length : (_categories.length > 6 ? 6 : _categories.length),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final color = _parseColor(cat.color);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _initialSearchCategoryId = cat.id;
                    _currentTab = 1;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        _getIconForName(cat.icon),
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        _formatCategoryName(cat.name(AppStrings.lang)),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTopMastersSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text(
                AppStrings.topMasters,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 1),
                child: Text(
                  AppStrings.viewAll,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _topMasters.length,
          itemBuilder: (context, index) {
            return MasterCard(
              master: _topMasters[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MasterDetailScreen(
                      apiService: widget.apiService,
                      masterId: _topMasters[index].id,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    _searchController.dispose();
    _socketSub?.cancel();
    HomeScreen.switchToTab = null;
    super.dispose();
  }
}
