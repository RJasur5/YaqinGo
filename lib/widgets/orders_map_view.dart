import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:latlong2/latlong.dart' hide Path;
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../utils/formatters.dart';
import '../services/api_service.dart';
import '../screens/client_profile_screen.dart';

class _MapMarkerItem {
  final bool isCompany;
  final dynamic primaryOrder;
  final List<dynamic> companyOrders;
  final LatLng originalPos;
  LatLng displayPos;

  _MapMarkerItem({
    required this.isCompany,
    required this.primaryOrder,
    required this.companyOrders,
    required this.originalPos,
  }) : displayPos = originalPos;
}

class OrdersMapView extends StatefulWidget {
  final List<dynamic> orders;
  final Function(dynamic) onOrderTap;
  final LatLng? userCenter;
  final ApiService? apiService;
  final Function(bool isNearby)? onNearbyToggled;

  const OrdersMapView({
    super.key,
    required this.orders,
    required this.onOrderTap,
    this.userCenter,
    this.apiService,
    this.onNearbyToggled,
  });

  @override
  State<OrdersMapView> createState() => _OrdersMapViewState();
}

class _OrdersMapViewState extends State<OrdersMapView> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  dynamic _selectedOrder;
  late AnimationController _pulseController;

  // Nearby mode
  bool _nearbyMode = false;
  bool _nearbyLoading = false;
  double? _userLat;
  double? _userLon;
  static const double _nearbyRadiusKm = 2.0;

  static const LatLng _tashkentCenter = LatLng(41.2995, 69.2401);

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _toggleNearby() async {
    if (_nearbyMode) {
      setState(() {
        _nearbyMode = false;
        _userLat = null;
        _userLon = null;
      });
      widget.onNearbyToggled?.call(false);
      return;
    }
    setState(() => _nearbyLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.isRu ? 'Разрешение на геолокацию не выдано' : 'Joylashuv ruxsati berilmagan')),
          );
        }
        setState(() => _nearbyLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLat = pos.latitude;
        _userLon = pos.longitude;
        _nearbyMode = true;
        _nearbyLoading = false;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
      widget.onNearbyToggled?.call(true);
    } catch (e) {
      setState(() => _nearbyLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.isRu ? 'Не удалось получить геолокацию' : 'Joylashuvni aniqlashda xatolik')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    if (widget.userCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(widget.userCenter!, 14.0);
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrdersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userCenter != null && widget.userCenter != oldWidget.userCenter) {
      _mapController.move(widget.userCenter!, 14.0);
    }
  }

  LatLng _getOrderCoordinates(dynamic order, int index) {
    if (order['lat'] != null && order['lon'] != null) {
      try {
        final double lat = (order['lat'] is num) ? (order['lat'] as num).toDouble() : double.parse(order['lat'].toString());
        final double lon = (order['lon'] is num) ? (order['lon'] as num).toDouble() : double.parse(order['lon'].toString());
        return LatLng(lat, lon);
      } catch (_) {}
    }

    final orderId = (order['id'] ?? order['order_id'] ?? index) as int;
    final double latOffset = (((orderId * 23) % 60) - 30) * 0.0035;
    final double lonOffset = (((orderId * 37) % 60) - 30) * 0.0045;
    return LatLng(
      _tashkentCenter.latitude + latOffset,
      _tashkentCenter.longitude + lonOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply nearby filter if active
    final visibleOrders = (_nearbyMode && _userLat != null && _userLon != null)
        ? widget.orders.where((o) {
            final idx = widget.orders.indexOf(o);
            final pos = _getOrderCoordinates(o, idx);
            return _distanceKm(_userLat!, _userLon!, pos.latitude, pos.longitude) <= _nearbyRadiusKm;
          }).toList()
        : widget.orders;

    final markers = <Marker>[];

    // User Location Marker
    if (_nearbyMode && _userLat != null && _userLon != null) {
      markers.add(
        Marker(
          width: 50,
          height: 50,
          point: LatLng(_userLat!, _userLon!),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Map<String, List<dynamic>> groupedCompanyOrders = {};
    final List<MapEntry<dynamic, int>> individualOrders = [];

    for (int i = 0; i < visibleOrders.length; i++) {
      final order = visibleOrders[i];
      
      final client = order['client'];
      final isCompanyOrder = (client != null && client['account_type'] == 'company') ||
          order['account_type'] == 'company' ||
          order['is_company'] == true ||
          order['company_logo'] != null;

      if (isCompanyOrder) {
        final companyKey = (client != null && client['id'] != null)
            ? 'client_${client['id']}'
            : (order['client_id'] != null
                ? 'client_${order['client_id']}'
                : (order['company_name'] ?? 'company_${order['id']}'));

        groupedCompanyOrders.putIfAbsent(companyKey.toString(), () => []).add(order);
      } else {
        individualOrders.add(MapEntry(order, i));
      }
    }

    // Collect all marker items (both company groups and individual orders)
    final List<_MapMarkerItem> allItems = [];

    int companyIdx = 0;
    groupedCompanyOrders.forEach((companyKey, companyOrdersList) {
      if (companyOrdersList.isEmpty) return;
      final firstOrder = companyOrdersList.first;
      final pos = _getOrderCoordinates(firstOrder, companyIdx++);
      allItems.add(_MapMarkerItem(
        isCompany: true,
        primaryOrder: firstOrder,
        companyOrders: companyOrdersList,
        originalPos: pos,
      ));
    });

    for (final entry in individualOrders) {
      final order = entry.key;
      final i = entry.value;
      final pos = _getOrderCoordinates(order, i);
      allItems.add(_MapMarkerItem(
        isCompany: false,
        primaryOrder: order,
        companyOrders: [],
        originalPos: pos,
      ));
    }

    // Spatial clustering & dispersion: prevent overlapping markers
    const double collisionThreshold = 0.00035; // ~35 meters
    final List<List<_MapMarkerItem>> clusters = [];

    for (final item in allItems) {
      bool added = false;
      for (final cluster in clusters) {
        final center = cluster.first.originalPos;
        final dLat = (item.originalPos.latitude - center.latitude).abs();
        final dLon = (item.originalPos.longitude - center.longitude).abs();
        if (dLat < collisionThreshold && dLon < collisionThreshold) {
          cluster.add(item);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add([item]);
      }
    }

    // If multiple items share essentially the exact same spot, spread them in a circle
    for (final cluster in clusters) {
      if (cluster.length > 1) {
        final baseCenter = cluster.first.originalPos;
        final n = cluster.length;
        final double radius = n == 2 ? 0.00038 : (0.00042 + 0.00004 * n);
        final double cosLat = math.cos(baseCenter.latitude * (math.pi / 180.0));
        final double safeCos = cosLat.abs() > 0.01 ? cosLat.abs() : 1.0;

        for (int k = 0; k < n; k++) {
          final double angle = (2 * math.pi * k) / n - (math.pi / 2);
          final double offsetLat = radius * math.sin(angle);
          final double offsetLon = (radius * math.cos(angle)) / safeCos;
          cluster[k].displayPos = LatLng(
            baseCenter.latitude + offsetLat,
            baseCenter.longitude + offsetLon,
          );
        }
      }
    }

    // Build markers for map rendering
    for (final item in allItems) {
      final order = item.primaryOrder;
      final isSelected = _selectedOrder != null &&
          (_selectedOrder['id'] ?? _selectedOrder['order_id']) == (order['id'] ?? order['order_id']);

      if (item.isCompany) {
        final client = order['client'];
        final companyLogo = order['company_logo'] ??
            order['company_banner'] ??
            (client != null ? (client['company_logo'] ?? client['company_banner'] ?? client['avatar']) : null) ??
            order['client_avatar'];
        final logoUrl = companyLogo?.toString();

        final vacanciesCount = item.companyOrders.length;
        final badgeText = vacanciesCount > 1
            ? (AppStrings.isRu ? '$vacanciesCount вак.' : '$vacanciesCount vak.')
            : (order['price'] != null
                ? '${PriceFormatter.format(order['price'])} ${AppStrings.sum}'
                : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan'));

        markers.add(
          Marker(
            width: 88,
            height: 94,
            point: item.displayPos,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedOrder = order);
                _showCompanyVacanciesModal(context, order, item.companyOrders);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDark : AppColors.primary,
                        width: 3.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl.startsWith('http')
                                  ? logoUrl
                                  : '${ApiConfig.baseUrl.replaceAll("/api", "")}$logoUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primary,
                                child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
                              ),
                            )
                          : Container(
                              color: AppColors.primary,
                              child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
                            ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(12, 6),
                    painter: _TrianglePainter(
                      color: isSelected ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        final price = order['price'];
        final priceText = price != null ? '${PriceFormatter.format(price)} ${AppStrings.sum}' : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan');

        markers.add(
          Marker(
            width: 140,
            height: 75,
            point: item.displayPos,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOrder = order;
                });
                _showOrderBottomSheet(context, order);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            priceText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: const Size(12, 6),
                    painter: _TrianglePainter(
                      color: isSelected ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primaryDark : AppColors.primary,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
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
    }

    final centerPoint = widget.userCenter ?? _tashkentCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: 13.5,
            minZoom: 10.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Google Maps Tile Layer
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.yaqin.findix',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // "Рядом" button overlay on map (top-right)
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _nearbyLoading ? null : _toggleNearby,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _nearbyMode ? AppColors.primary : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_nearbyLoading)
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _nearbyMode ? Colors.white : AppColors.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: _nearbyMode ? Colors.white : AppColors.primary,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.isRu ? 'Рядом' : 'Yaqin',
                    style: TextStyle(
                      color: _nearbyMode ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderBottomSheet(BuildContext context, dynamic order) {
    final theme = Theme.of(context);
    final title = order['subcategory_name_ru'] ?? order['subcategory_name_uz'] ?? order['title'] ?? (AppStrings.isRu ? 'Заказ' : 'Buyurtma');
    final description = order['description'] ?? '';
    final district = order['district'] ?? (AppStrings.isRu ? 'Ташкент' : 'Toshkent');
    final price = order['price'];
    final priceText = price != null ? '${PriceFormatter.format(price)} ${AppStrings.sum}' : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan');

    final client = order['client'];
    final isCompanyOrder = (client != null && client['account_type'] == 'company') ||
        order['account_type'] == 'company' ||
        order['is_company'] == true ||
        order['company_logo'] != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompanyOrder) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.isRu ? 'Официальная вакансия от компании' : 'Kompaniyadan rasmiy vakansiya',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    district,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              if (description.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onOrderTap(order);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    AppStrings.isRu ? 'Откликнуться / Принять заказ' : 'Javob berish / Qabul qilish',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompanyVacanciesModal(BuildContext context, dynamic order, List<dynamic> companyOrders) {
    final theme = Theme.of(context);
    final client = order['client'];
    final int? clientId = (client != null && client['id'] != null)
        ? client['id']
        : (order['client_id'] is int ? order['client_id'] : int.tryParse('${order['client_id']}'));
    final companyName = (client != null ? client['name'] : null) ??
        order['company_name'] ??
        order['client_name'] ??
        (AppStrings.isRu ? 'Компания' : 'Kompaniya');
    final companyLogo = order['company_logo'] ??
        order['company_banner'] ??
        (client != null ? (client['company_logo'] ?? client['company_banner'] ?? client['avatar']) : null) ??
        order['client_avatar'];
    final logoUrl = companyLogo?.toString();

    List<dynamic> activeCompanyOrders = List.from(companyOrders);
    bool hasRequestedAll = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          // If we have clientId and apiService, fetch ALL open company orders in the background
          if (clientId != null && widget.apiService != null && !hasRequestedAll) {
            hasRequestedAll = true;
            widget.apiService!.getAvailableOrders(clientId: clientId).then((allOrders) {
              if (allOrders.isNotEmpty && modalContext.mounted) {
                setModalState(() {
                  activeCompanyOrders = allOrders;
                });
              }
            }).catchError((_) {});
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Company Header info (Clickable to open Company Profile!)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (clientId != null && widget.apiService != null) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientProfileScreen(
                              clientId: clientId,
                              apiService: widget.apiService!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: logoUrl != null && logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl.startsWith('http')
                                          ? logoUrl
                                          : '${ApiConfig.baseUrl.replaceAll("/api", "")}$logoUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                                    )
                                  : const Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyName,
                                  style: TextStyle(
                                    color: theme.textTheme.titleLarge?.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      AppStrings.isRu ? 'Профиль компании' : 'Kompaniya profili',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppStrings.isRu ? 'Профиль' : 'Profil',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 10),

                  // Vacancies Title
                  Row(
                    children: [
                      const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${AppStrings.isRu ? "Открытые вакансии компании" : "Kompaniyaning ochiq vakansiyalari"} (${activeCompanyOrders.length})',
                        style: TextStyle(
                          color: theme.textTheme.titleMedium?.color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vacancies List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: activeCompanyOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = activeCompanyOrders[index];
                        final price = item['price'];
                        final priceStr = price != null ? '${PriceFormatter.format(price)} ${AppStrings.sum}' : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan');
                        final title = item['title'] ?? item['subcategory_name_ru'] ?? item['subcategory_name_uz'] ?? (AppStrings.isRu ? 'Вакансия' : 'Vakansiya');

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: theme.textTheme.titleMedium?.color,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priceStr,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, height: 1.4),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    widget.onOrderTap(item);
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppStrings.isRu ? 'Узнать подробнее' : 'Batafsil ma\'lumot',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
