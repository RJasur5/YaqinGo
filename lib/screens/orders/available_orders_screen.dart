import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/gradient_button.dart';
import '../../models/category.dart';
import '../client_profile_screen.dart';
import '../../widgets/rating_stars.dart';
import '../../config/api_config.dart';
import '../../widgets/full_screen_image.dart';
import '../../utils/date_utils.dart';
import '../../utils/formatters.dart';
import '../../services/auth_service.dart';
import '../../config/regions.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../models/order.dart';
import '../../widgets/orders_map_view.dart';
import 'chat_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final List<CategoryModel> categories;
  final int? initialCategoryId;
  final ValueChanged<bool>? onFullscreenChanged;
  const AvailableOrdersScreen({
    super.key,
    required this.apiService,
    required this.authService,
    this.categories = const [],
    this.initialCategoryId,
    this.onFullscreenChanged,
  });

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _isMapView = false;
  String? _error;
  
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String _searchQuery = '';
  String? _selectedSearchCity;
  String _selectedAccountTypeFilter = 'person'; // 'person' or 'company'

  final _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    widget.authService?.addListener(_onAuthChanged);
    _selectedCategoryId = widget.initialCategoryId;
    if (_selectedCategoryId != null && widget.categories.isNotEmpty) {
      final currentCat = widget.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => widget.categories.first,
      );
      if (currentCat.subcategories.isNotEmpty) {
        _selectedSubcategoryId = currentCat.subcategories.first.id;
      }
    }
    _loadOrders();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (_orders.isEmpty) setState(() => _isLoading = true);
    try {
      final orders = await widget.apiService.getAvailableOrders(
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
        city: _selectedSearchCity,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

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

  Future<void> _acceptOrder(int orderId) async {
    try {
      final res = await widget.apiService.acceptOrder(orderId);
      
      if (mounted) {
        // Show success snackbar
        final isCompanyResp = res != null && res['is_company'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCompanyResp
                    ? (AppStrings.isRu ? 'Отклик успешно отправлен!' : 'Murojaat muvaffaqiyatli yuborildi!')
                    : (AppStrings.isRu ? 'Заказ успешно принят!' : 'Buyurtma muvaffaqiyatli qabul qilindi!'),
              ),
              backgroundColor: Colors.green,
            ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('already accepted')) {
          _showAlreadyAcceptedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    }
  }

  void _showAlreadyAcceptedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              AppStrings.isRu ? 'Вы не успели' : 'Ulgurmadingiz',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          AppStrings.isRu 
            ? 'Этот заказ только что принял другой мастер. Не расстраивайтесь, скоро появятся новые заказы!' 
            : 'Bu buyurtmani boshqa usta qabul qilib bo\'ldi. Xafa bo\'lmang, tez orada yangi buyurtmalar paydo bo\'ladi!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadOrders();
            },
            child: Text(
              AppStrings.isRu ? 'Понятно' : 'Tushunarli',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authService.currentUser;
    final filteredOrders = _orders.where((order) {
      final client = order['client'];
      final bool isComp = order['is_company'] == true ||
          order['is_company'] == 1 ||
          order['is_company'] == 'true' ||
          (client != null && client['account_type'] == 'company') ||
          order['account_type'] == 'company' ||
          (order['company_logo'] != null && order['company_logo'].toString().isNotEmpty);

      if (!_isMapView) {
        return true;
      }

      if (_selectedAccountTypeFilter == 'person') {
        return !isComp;
      } else if (_selectedAccountTypeFilter == 'company') {
        return isComp;
      }
      return true;
    }).toList();

    final canPop = Navigator.of(context).canPop();
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: (canPop || !_isMapView)
            ? AppBar(
                title: Text(AppStrings.isRu ? 'Доступные заказы' : 'Mavjud buyurtmalar'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: theme.textTheme.bodyLarge?.color,
                actions: [
                  IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded)),
                ],
              )
            : null,
        body: SafeArea(
          top: _isMapView,
          bottom: !_isMapView,
          child: Column(
            children: [
              _buildSearchAndFilters(),
              Expanded(
                child: Stack(
                  children: [
                    _isMapView
                        ? Stack(
                            children: [
                              OrdersMapView(
                                key: ValueKey('orders_map_${user?.latitude}_${user?.longitude}'),
                                orders: filteredOrders,
                                apiService: widget.apiService,
                                userCenter: (user != null && user.latitude != null && user.longitude != null)
                                    ? LatLng(user.latitude!, user.longitude!)
                                    : null,
                                onNearbyToggled: (isNearby) {
                                  if (isNearby) {
                                    setState(() {
                                      _selectedCategoryId = null;
                                      _selectedSubcategoryId = null;
                                      _selectedSearchCity = null;
                                    });
                                    _loadOrders();
                                  }
                                },
                                onOrderTap: (order) {
                                  _showOrderDetail(order);
                                },
                              ),
                              if (_isLoading)
                                Positioned(
                                  top: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : _isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : filteredOrders.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _loadOrders,
                                    color: AppColors.primary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                      itemCount: filteredOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = filteredOrders[index];
                                        return _buildOrderCard(order);
                                      },
                                    ),
                                  ),

                    // Floating Controls (Filter Ribbon + View Toggle Button)
                    if (!_isLoading)
                      Positioned(
                        bottom: 20,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Single Account Type Filter Button (Shown ONLY when Map view is active)
                            if (_isMapView) ...[
                              Flexible(
                                flex: 3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _buildSingleAccountTypeButton(),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Toggle View Button
                            Flexible(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isMapView = !_isMapView;
                                      widget.onFullscreenChanged?.call(_isMapView);
                                      // Auto-select first category when entering map with "Все"
                                      if (_isMapView && widget.categories.isNotEmpty) {
                                        if (_selectedCategoryId == null) {
                                          _selectedCategoryId = widget.categories.first.id;
                                        }
                                        final currentCat = widget.categories.firstWhere(
                                          (c) => c.id == _selectedCategoryId,
                                          orElse: () => widget.categories.first,
                                        );
                                        final hasSub = currentCat.subcategories.any((s) => s.id == _selectedSubcategoryId);
                                        if (!hasSub && currentCat.subcategories.isNotEmpty) {
                                          _selectedSubcategoryId = currentCat.subcategories.first.id;
                                        }
                                        _loadOrders();
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isMapView ? theme.cardTheme.color : AppColors.primary,
                                      borderRadius: BorderRadius.circular(30),
                                      border: _isMapView ? Border.all(color: AppColors.primary, width: 1.5) : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.35),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
                                          color: _isMapView ? AppColors.primary : Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isMapView
                                              ? (AppStrings.isRu ? 'Список' : 'Ro\'yxat')
                                              : (AppStrings.isRu ? 'Карта' : 'Xarita'),
                                          style: TextStyle(
                                            color: _isMapView ? AppColors.primary : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (!_isMapView)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadOrders();
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: Icon(Icons.search_rounded, color: theme.textTheme.bodySmall?.color),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: theme.textTheme.bodySmall?.color),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadOrders();
                          },
                        )
                      : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCityPicker(),
            ],
          ),
        ),
        if (widget.categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _isMapView ? widget.categories.length : widget.categories.length + 1,
              itemBuilder: (context, index) {
                if (!_isMapView && index == 0) {
                  return _buildFilterChip(
                    label: AppStrings.isRu ? 'Все' : 'Barchasi',
                    selected: _selectedCategoryId == null,
                    onSelected: (s) {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedSubcategoryId = null;
                      });
                      _loadOrders();
                    },
                  );
                }
                final catIndex = _isMapView ? index : index - 1;
                final cat = widget.categories[catIndex];
                return _buildFilterChip(
                  label: cat.name(AppStrings.lang),
                  selected: _selectedCategoryId == cat.id,
                  onSelected: (s) {
                    setState(() {
                      _selectedCategoryId = cat.id;
                      final existsInNewCat = cat.subcategories.any((sub) => sub.id == _selectedSubcategoryId);
                      if (!existsInNewCat) {
                        _selectedSubcategoryId = cat.subcategories.isNotEmpty ? cat.subcategories.first.id : null;
                      }
                    });
                    _loadOrders();
                  },
                );
              },
            ),
          ),
        if (_selectedCategoryId != null) ...[
          const SizedBox(height: 12),
          _buildSubcategoryRibbon(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCityPicker() {
    final theme = Theme.of(context);
    return PopupMenuButton<String?>(
      initialValue: _selectedSearchCity,
      tooltip: AppStrings.isRu ? 'Выбрать город' : 'Shaharni tanlash',
      onSelected: (String? value) {
        setState(() {
          _selectedSearchCity = value;
        });
        _loadOrders();
      },
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded, // filter/settings icon as requested
              color: _selectedSearchCity == null ? theme.hintColor : theme.primaryColor,
              size: 24,
            ),
            if (_selectedSearchCity != null)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),

      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.all_inclusive, size: 18, color: theme.hintColor),
                const SizedBox(width: 10),
                Text(AppStrings.isRu ? 'Все города' : 'Barcha shaharlar'),
              ],
            ),
          ),
          ...RegionsConfig.regionKeys.map((String key) {
            final displayName = RegionsConfig.getDisplayName(key);
            final isSelected = _selectedSearchCity == displayName;
            return PopupMenuItem<String?>(
              value: displayName,
              child: Row(
                children: [
                  Icon(
                    Icons.location_city_rounded, 
                    size: 18, 
                    color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.4)
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    );
  }


  Widget _buildFilterChip({required String label, required bool selected, required Function(bool) onSelected}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: theme.cardTheme.color,
        selectedColor: theme.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildSubcategoryRibbon() {
    final cat = widget.categories.firstWhere((c) => c.id == _selectedCategoryId);
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _isMapView ? cat.subcategories.length : cat.subcategories.length + 1,
        itemBuilder: (context, index) {
          if (!_isMapView && index == 0) {
            return _buildSmallChip(
              label: AppStrings.isRu ? 'Все специальности' : 'Barcha mutaxassisliklar',
              selected: _selectedSubcategoryId == null,
              onTap: () {
                setState(() => _selectedSubcategoryId = null);
                _loadOrders();
              },
            );
          }
          final subIndex = _isMapView ? index : index - 1;
          final sub = cat.subcategories[subIndex];
          return _buildSmallChip(
            label: sub.name(AppStrings.lang),
            selected: _selectedSubcategoryId == sub.id,
            onTap: () {
              setState(() => _selectedSubcategoryId = sub.id);
              _loadOrders();
            },
          );
        },
      ),
    );
  }

  Widget _buildSmallChip({required String label, required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_rounded, size: 80, color: theme.textTheme.bodySmall?.color?.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            AppStrings.isRu ? 'Нет доступных заказов' : 'Mavjud buyurtmalar yo\'q',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isRu ? 'Попробуйте обновить позже' : 'Keyinroq yangilab ko\'ring',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final theme = Theme.of(context);
    final subName = AppStrings.isRu ? order['subcategory_name_ru'] : order['subcategory_name_uz'];
    final date = DateTimeUtils.parseUtc(order['created_at']);
    final formattedDate = DateTimeUtils.formatFull(date);
    final bool isCompany = order['is_company'] == true &&
        order['company_name'] != null &&
        order['company_name'].toString().trim().isNotEmpty;
    final int reqWorkers = (order['required_workers'] is int)
        ? (order['required_workers'] as int)
        : (int.tryParse(order['required_workers']?.toString() ?? '1') ?? 1);
    
    // Debug to console to verify the 5-hour shift
    debugPrint('TIME DEBUG: Raw=${order['created_at']} | Local=${date.toString()}');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOrderDetail(order),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subName,
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
            if (isCompany) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_rounded, color: Colors.purple, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.isRu ? 'Набор персонала (HR)' : 'Xodimlar yollash (HR)',
                      style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.isRu 
                  ? 'Уже откликнулось: ${order['applicants_count'] ?? 0} чел.' 
                  : 'Allaqachon ${order['applicants_count'] ?? 0} kishi murojaat qildi',
                style: TextStyle(color: theme.primaryColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ] else if (reqWorkers > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.blue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.isRu ? 'Требуется: $reqWorkers чел.' : 'Kerak: $reqWorkers kishi',
                      style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.isRu
                    ? 'Уже откликнулось: ${order['applicants_count'] ?? 0} из $reqWorkers чел.'
                    : 'Murojaat qildi: $reqWorkers tadan ${order['applicants_count'] ?? 0} kishi',
                style: TextStyle(color: theme.primaryColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: theme.textTheme.bodyMedium?.color, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order['city']}, ${order['district'] ?? ''}',
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
            const SizedBox(height: 16),
            Text(
              order['description'],
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _buildOptionsRow(order),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor.withOpacity(0.1)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ClientProfileScreen(
                      clientId: order['client_id'],
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () {
                       final avatarUrl = order['client_avatar'] != null && order['client_avatar'].toString().isNotEmpty
                         ? (order['client_avatar'].toString().startsWith('http') 
                             ? order['client_avatar'] 
                             : '${ApiConfig.baseUrl}${order['client_avatar']}')
                         : null;
                       if (avatarUrl != null) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: avatarUrl, tag: 'order_avatar_${order['id']}')));
                       }
                     },
                     child: Hero(
                       tag: 'order_avatar_${order['id']}',
                       child: ClipOval(
                         child: order['client_avatar'] != null && order['client_avatar'].toString().isNotEmpty
                           ? Image.network(
                               order['client_avatar'].toString().startsWith('http') 
                                 ? order['client_avatar'] 
                                 : '${ApiConfig.baseUrl}${order['client_avatar']}',
                               width: 40,
                               height: 40,
                               fit: BoxFit.cover,
                               errorBuilder: (context, error, stackTrace) => Icon(Icons.person_outline_rounded, color: theme.primaryColor, size: 40),
                             )
                           : Icon(Icons.person_outline_rounded, color: theme.primaryColor, size: 40),
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: GestureDetector(
                       behavior: HitTestBehavior.opaque,
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (ctx) => ClientProfileScreen(
                               clientId: order['client_id'],
                               apiService: widget.apiService,
                               hidePhone: true,
                             ),
                           ),
                         );
                       },
                       child: Text(
                         order['client_name'].toString().capitalizeWords(),
                         style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 15),
                       ),
                     ),
                   ),
                   Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (order['price'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${PriceFormatter.format(order['price'])} ${AppStrings.sum}',
                  style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            // Подробнее + Позвонить/Откликнуться buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetail(order),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      AppStrings.isRu ? 'Подробнее' : 'Batafsil',
                      style: TextStyle(color: theme.primaryColor, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final bool hasApplied = order['has_applied'] == true;
                      final bool isCompany = order['is_company'] == true;

                      // Company: gray after applying
                      if (isCompany && hasApplied) {
                        return SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              AppStrings.isRu ? 'Отправлено' : 'Yuborildi',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        );
                      }

                      if (isCompany) {
                        return SizedBox(
                          height: 50,
                          child: GradientButton(
                            text: AppStrings.isRu ? 'Откликнуться' : 'Murojaat qilish',
                            onPressed: () => _acceptOrder(order['id']),
                          ),
                        );
                      }

                      // Regular order — always green Позвонить, unlimited calls
                      final String rawPhone = (order['client_phone'] ?? '').toString().replaceAll(RegExp(r'[^\d+]'), '');
                      return SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Open phone dialer immediately
                            if (rawPhone.isNotEmpty) {
                              final uri = Uri.parse('tel:$rawPhone');
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                debugPrint('Could not launch phone: $e');
                              }
                            }
                            // Record call in background silently
                            _acceptOrder(order['id']);
                          },
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: Text(
                            AppStrings.isRu ? 'Позвонить' : 'Qo\'ng\'iroq',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 3,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }


  void _showOrderDetail(dynamic order) {
    final theme = Theme.of(context);
    final subName = AppStrings.isRu ? order['subcategory_name_ru'] : order['subcategory_name_uz'];
    final date = DateTimeUtils.parseUtc(order['created_at']);
    final formattedDate = DateTimeUtils.formatFull(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subName,
                      style: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(formattedDate, style: TextStyle(color: theme.hintColor, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: theme.hintColor, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order['city']}${order['district'] != null ? ', ${order['district']}' : ''}',
                      style: TextStyle(color: theme.hintColor, fontSize: 14),
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
              if (order['price'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${PriceFormatter.format(order['price'])} ${AppStrings.sum}',
                  style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text(
                AppStrings.isRu ? 'Описание' : 'Tavsif',
                style: TextStyle(color: theme.hintColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    order['description'],
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final bool hasApplied = order['has_applied'] == true;
                  final bool isCompany = order['is_company'] == true;

                  // Company: gray after applying
                  if (isCompany && hasApplied) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(
                          AppStrings.isRu ? 'Отклик отправлен' : 'Murojaat yuborilgan',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    );
                  }

                  if (isCompany) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GradientButton(
                        text: AppStrings.isRu ? 'Откликнуться' : 'Murojaat qilish',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _acceptOrder(order['id']);
                        },
                      ),
                    );
                  }

                  // Regular order — Позвонить
                  final String rawPhone = (order['client_phone'] ?? '').toString().replaceAll(RegExp(r'[^\d+]'), '');
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (rawPhone.isNotEmpty) {
                          final uri = Uri.parse('tel:$rawPhone');
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Could not launch phone: $e');
                          }
                        }
                        _acceptOrder(order['id']);
                      },
                      icon: const Icon(Icons.phone_rounded, size: 20),
                      label: Text(
                        AppStrings.isRu ? 'Позвонить' : 'Qo\'ng\'iroq qilish',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                    ),
                  );
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

  Widget _buildAccountTypeChip(String typeKey, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedAccountTypeFilter == typeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountTypeFilter = typeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.dividerColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAccountTypeButton() {
    final isCompany = _selectedAccountTypeFilter == 'company';

    final label = isCompany
        ? (AppStrings.isRu ? '🏢 Компании' : '🏢 Kompaniyalar')
        : (AppStrings.isRu ? '👤 Физ. лица' : '👤 Jismoniy');
    final icon = isCompany ? Icons.business_rounded : Icons.person_rounded;
    final bgColor = AppColors.primary;
    final borderColor = AppColors.primaryDark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountTypeFilter = isCompany ? 'person' : 'company';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.authService?.removeListener(_onAuthChanged);
    _searchController.dispose();
    super.dispose();
  }
}
