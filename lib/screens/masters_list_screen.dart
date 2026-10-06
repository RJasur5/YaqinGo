import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../models/category.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/master_card.dart';
import '../widgets/master_map_view.dart';
import 'master_detail_screen.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../config/regions.dart';

class MastersListScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService? authService;
  final List<CategoryModel> categories;
  final int? initialCategoryId;
  final ValueChanged<bool>? onFullscreenChanged;

  const MastersListScreen({
    super.key,
    required this.apiService,
    this.authService,
    this.categories = const [],
    this.initialCategoryId,
    this.onFullscreenChanged,
  });

  @override
  State<MastersListScreen> createState() => _MastersListScreenState();
}

class _MastersListScreenState extends State<MastersListScreen> {
  List<MasterModel> _masters = [];
  bool _isLoading = true;
  bool _isMapView = false;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String _selectedAccountTypeFilter = 'all'; // 'all', 'person', 'company'
  String _searchQuery = '';
  String _sortBy = 'rating';
  String? _selectedCity;
  final _searchController = TextEditingController();

  final Set<int> _favoriteMasterIds = {};

  @override
  void initState() {
    super.initState();
    widget.authService?.addListener(_onAuthChanged);
    // Only set category if explicitly passed (e.g. from home screen)
    // Otherwise default to "Все" (null) in list mode
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
      _autoSelectFirstSubcategory();
    }
    // Always default city to Tashkent
    _selectedCity = RegionsConfig.getDisplayName(RegionsConfig.regionKeys.first);
    _loadMasters();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await widget.apiService.getFavorites();
      if (mounted) {
        setState(() {
          _favoriteMasterIds.clear();
          _favoriteMasterIds.addAll(favs.map((m) => m.id));
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(MasterModel master) async {
    final currentlyFav = _favoriteMasterIds.contains(master.id) || master.isFavorite;
    setState(() {
      if (currentlyFav) {
        _favoriteMasterIds.remove(master.id);
      } else {
        _favoriteMasterIds.add(master.id);
      }
    });
    try {
      await widget.apiService.toggleFavorite(master.id);
    } catch (_) {}
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
      _loadMasters();
      _loadFavorites();
    }
  }

  void _autoSelectFirstSubcategory() {
    final cat = _selectedCategory;
    if (cat != null && cat.subcategories.isNotEmpty) {
      _selectedSubcategoryId = cat.subcategories.first.id;
    } else {
      _selectedSubcategoryId = null;
    }
  }

  Future<void> _loadMasters() async {
    // Only show loading spinner on initial load (no data yet)
    if (_masters.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final masters = await widget.apiService.getMasters(
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
        city: _selectedCity,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
      );
      if (mounted) {
        setState(() {
          _masters = masters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  CategoryModel? get _selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return widget.categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: canPop ? AppBar(
        title: Text(AppStrings.isRu ? 'Категории' : 'Kategoriyalar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ) : null,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar - HIDDEN when map is open
              if (!_isMapView)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadMasters();
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadMasters();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                          onPressed: _showSortDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // City Filter - HIDDEN when map is open
              if (!_isMapView)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: theme.cardTheme.color,
                    decoration: InputDecoration(
                      hintText: AppStrings.isRu ? 'Все города' : 'Barcha shaharlar',
                      prefixIcon: Icon(Icons.location_on_rounded, color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: theme.cardTheme.color,
                    ),
                    icon: Icon(Icons.arrow_drop_down_rounded, color: theme.textTheme.bodySmall?.color),
                    items: [
                      DropdownMenuItem<String>(
                        value: null, 
                        child: Text(AppStrings.isRu ? 'Все города' : 'Barcha shaharlar', style: theme.textTheme.bodyLarge)
                      ),
                      ...RegionsConfig.regionKeys.map((key) => DropdownMenuItem<String>(
                        value: RegionsConfig.getDisplayName(key), 
                        child: Text(RegionsConfig.getDisplayName(key), style: theme.textTheme.bodyLarge)
                      )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                      });
                      _loadMasters();
                    },
                  ),
              ),

              // Category Ribbon - "Vse" visible in list mode only
              if (widget.categories.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _isMapView ? widget.categories.length : widget.categories.length + 1,
                    itemBuilder: (context, index) {
                      // In list mode: index 0 = "Все", rest = categories
                      if (!_isMapView && index == 0) {
                        return _buildFilterChip(
                          label: AppStrings.isRu ? 'Все' : 'Barchasi',
                          selected: _selectedCategoryId == null,
                          onSelected: (s) {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedSubcategoryId = null;
                            });
                            _loadMasters();
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
                            _selectedSubcategoryId = null;
                          });
                          _autoSelectFirstSubcategory();
                          _loadMasters();
                        },
                      );
                    },
                  ),
                ),

              // Subcategory Ribbon - NO "Vse specialnosti"
              if (_selectedCategory != null && _selectedCategory!.subcategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedCategory!.subcategories.length,
                    itemBuilder: (context, index) {
                      final sub = _selectedCategory!.subcategories[index];
                      return _buildSmallChip(
                        label: sub.name(AppStrings.lang),
                        selected: _selectedSubcategoryId == sub.id,
                        onTap: () {
                          setState(() => _selectedSubcategoryId = sub.id);
                          _loadMasters();
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Masters list or Map View
              Expanded(
                child: () {
                  final filteredMasters = _masters.where((m) {
                    final isComp = m.accountType == 'company' ||
                        (m.companyLogo != null && m.companyLogo!.isNotEmpty) ||
                        (m.companyBanner != null && m.companyBanner!.isNotEmpty);
                    if (isComp) return false;
                    return true;
                  }).toList();

                  return Stack(
                    children: [
                      _isMapView
                          ? Stack(
                              children: [
                                MasterMapView(
                                  key: ValueKey('master_map_${widget.authService?.currentUser?.latitude}_${widget.authService?.currentUser?.longitude}'),
                                  masters: filteredMasters,
                                  userCenter: (widget.authService?.currentUser != null &&
                                          widget.authService!.currentUser!.latitude != null &&
                                          widget.authService!.currentUser!.longitude != null)
                                      ? LatLng(widget.authService!.currentUser!.latitude!,
                                          widget.authService!.currentUser!.longitude!)
                                      : null,
                                  onNearbyToggled: (isNearby) {
                                    if (isNearby) {
                                      setState(() {
                                        _selectedCategoryId = null;
                                        _selectedSubcategoryId = null;
                                        _selectedAccountTypeFilter = 'all';
                                      });
                                      _loadMasters();
                                    }
                                  },
                                  onMasterTap: (master) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MasterDetailScreen(
                                          apiService: widget.apiService,
                                          masterId: master.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Small loading indicator overlay (doesn't hide the map)
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
                              : filteredMasters.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                                          const SizedBox(height: 16),
                                          Text(
                                            AppStrings.isRu ? 'Мастера не найдены' : "Ustalar topilmadi",
                                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadMasters,
                                      color: AppColors.primary,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                                        itemCount: filteredMasters.length,
                                        itemBuilder: (context, index) {
                                          return MasterCard(
                                            master: filteredMasters[index],
                                            isFavorite: _favoriteMasterIds.contains(filteredMasters[index].id) || filteredMasters[index].isFavorite,
                                            onFavorite: () => _toggleFavorite(filteredMasters[index]),
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MasterDetailScreen(
                                                    apiService: widget.apiService,
                                                    masterId: filteredMasters[index].id,
                                                  ),
                                                ),
                                              );
                                              _loadFavorites();
                                            },
                                          );
                                        },
                                      ),
                                    ),

                      // Floating Controls Ribbon over Map / List View
                      if (!_isLoading)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isMapView = !_isMapView;
                                  // When entering map with "Все" selected, auto-pick first category
                                  if (_isMapView && _selectedCategoryId == null && widget.categories.isNotEmpty) {
                                    _selectedCategoryId = widget.categories.first.id;
                                    _autoSelectFirstSubcategory();
                                    _loadMasters();
                                  }
                                });
                                widget.onFullscreenChanged?.call(_isMapView);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isMapView
                                          ? (AppStrings.isRu ? 'Списком' : 'Ro\'yxatda')
                                          : '${AppStrings.isRu ? "На карте" : "Xaritada"} (${filteredMasters.length})',
                                      style: TextStyle(
                                        color: _isMapView ? AppColors.primary : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }(),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showSortDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 24),
            Text(
              AppStrings.sortBy, 
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            _sortTile('rating', AppStrings.byRating, Icons.star_rounded),
            _sortTile('experience', AppStrings.byExperience, Icons.work_history_rounded),
            _sortTile('price', AppStrings.byPrice, Icons.attach_money_rounded),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortTile(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final selected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: selected ? theme.primaryColor : theme.textTheme.bodySmall?.color),
      title: Text(label, style: TextStyle(color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color)),
      trailing: selected ? Icon(Icons.check_rounded, color: theme.primaryColor) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        _loadMasters();
      },
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
        : (AppStrings.isRu ? '👤 Частные мастера' : '👤 Jismoniy ustalar');
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
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
