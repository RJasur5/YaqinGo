import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:latlong2/latlong.dart' hide Path;
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../config/region_geo.dart';
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
  double _currentZoom = 13.5;
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

  bool _hasExactPoint(dynamic order) =>
      (order['lat'] != null || order['latitude'] != null) &&
      (order['lon'] != null || order['longitude'] != null);

  /// Area (city / district) for orders where the user didn't pick a point on the map.
  GeoArea? _orderArea(dynamic order) {
    if (_hasExactPoint(order)) return null;
    return RegionGeo.areaFor(order['city']?.toString(), order['district']?.toString());
  }

  LatLng _getOrderCoordinates(dynamic order, int index) {
    if (_hasExactPoint(order)) {
      try {
        final rawLat = order['lat'] ?? order['latitude'];
        final rawLon = order['lon'] ?? order['longitude'];
        final double lat = (rawLat is num) ? rawLat.toDouble() : double.parse(rawLat.toString());
        final double lon = (rawLon is num) ? rawLon.toDouble() : double.parse(rawLon.toString());
        return LatLng(lat, lon);
      } catch (_) {}
    }

    // No exact point: place the order at the center of the selected city / district
    final area = _orderArea(order);
    if (area != null) return area.center;

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
      final bool hasBranch = (order['branch_id'] != null && order['branch_id'].toString().isNotEmpty) ||
          (order['branch_name'] != null && order['branch_name'].toString().isNotEmpty);
      final isCompanyOrder = (client != null && client['account_type'] == 'company') ||
          order['account_type'] == 'company' ||
          order['is_company'] == true ||
          order['company_logo'] != null ||
          hasBranch;

      if (isCompanyOrder) {
        final companyId = (client != null && client['id'] != null)
            ? client['id']
            : (order['client_id'] ?? order['company_name'] ?? order['id']);

        // Group strictly by branch_id or branch_name so vacancies posted by branch admin (292)
        // and company (340) for the SAME branch merge into a SINGLE pin on the map!
        String groupKey;
        if (order['branch_id'] != null && order['branch_id'].toString().isNotEmpty) {
          groupKey = 'branch_${order['branch_id']}';
        } else if (order['branch_name'] != null && order['branch_name'].toString().trim().isNotEmpty) {
          groupKey = 'bname_${order['branch_name'].toString().trim().toLowerCase()}';
        } else {
          final locKey = (order['lat'] != null && order['lon'] != null)
              ? 'loc_${(order['lat'] as num).toDouble().toStringAsFixed(4)}_${(order['lon'] as num).toDouble().toStringAsFixed(4)}'
              : 'main';
          groupKey = 'comp_${companyId}_$locKey';
        }

        groupedCompanyOrders.putIfAbsent(groupKey, () => []).add(order);
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

    // Highlight city / district areas for individual orders without an exact map point
    final Map<String, GeoArea> highlightAreas = {};
    for (final entry in individualOrders) {
      final area = _orderArea(entry.key);
      if (area != null) highlightAreas.putIfAbsent(area.key, () => area);
    }
    const areaColor = Color(0xFF2563EB);
    final areaCircles = highlightAreas.values.map((a) => CircleMarker(
          point: a.center,
          radius: a.radiusMeters,
          useRadiusInMeter: true,
          color: areaColor.withValues(alpha: a.isDistrict ? 0.14 : 0.08),
          borderColor: areaColor.withValues(alpha: 0.65),
          borderStrokeWidth: a.isDistrict ? 2.0 : 2.5,
        )).toList();

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

    // Build markers for map rendering with adaptive zoom levels
    final isZoomFar = _currentZoom < 11.5;
    final isZoomMid = _currentZoom >= 11.5 && _currentZoom < 13.5;

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
        String badgeText = '';
        if (vacanciesCount > 0) {
          if (AppStrings.isRu) {
            if (vacanciesCount % 10 == 1 && vacanciesCount % 100 != 11) {
              badgeText = '$vacanciesCount вакансия';
            } else if (vacanciesCount % 10 >= 2 && vacanciesCount % 10 <= 4 && (vacanciesCount % 100 < 10 || vacanciesCount % 100 >= 20)) {
              badgeText = '$vacanciesCount вакансии';
            } else {
              badgeText = '$vacanciesCount вакансий';
            }
          } else {
            badgeText = '$vacanciesCount ta vakansiya';
          }
        }

        if (isZoomFar) {
          // Macro Zoom (< 11.5): Micro glowing dot marker (prevents overlap with 400-500 markers)
          markers.add(
            Marker(
              width: 22,
              height: 22,
              point: item.displayPos,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(item.displayPos, 14.0);
                  setState(() => _selectedOrder = order);
                  _showCompanyVacanciesModal(context, order, item.companyOrders);
                },
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (isZoomMid) {
          // Mid Zoom (11.5 - 13.5): Compact 36px pin with badge counter, no giant bubble
          markers.add(
            Marker(
              width: 44,
              height: 48,
              point: item.displayPos,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedOrder = order);
                  _showCompanyVacanciesModal(context, order, item.companyOrders);
                },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDark : AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
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
                                cacheWidth: 72,
                                cacheHeight: 72,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primary,
                                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
                                ),
                              )
                            : Container(
                                color: AppColors.primary,
                                child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
                              ),
                      ),
                    ),
                    if (vacanciesCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: Text(
                            '$vacanciesCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Close Zoom (>= 13.5): Full rich executive pin
          markers.add(
            Marker(
              width: 96,
              height: vacanciesCount > 0 ? 94 : 56,
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
                                cacheWidth: 104,
                                cacheHeight: 104,
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
                    if (vacanciesCount > 0) ...[
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
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        // Individual Order Marker
        final price = order['price'];
        final priceText = price != null ? '${PriceFormatter.format(price)} ${AppStrings.sum}' : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan');

        if (isZoomFar) {
          // Far zoom: 16px sleek blue dot
          markers.add(
            Marker(
              width: 20,
              height: 20,
              point: item.displayPos,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(item.displayPos, 14.0);
                  setState(() => _selectedOrder = order);
                  _showOrderBottomSheet(context, order);
                },
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (isZoomMid) {
          // Mid zoom: 32px neat circle with work icon
          markers.add(
            Marker(
              width: 38,
              height: 42,
              point: item.displayPos,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedOrder = order);
                  _showOrderBottomSheet(context, order);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.work_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          );
        } else {
          // Close zoom: Full price chip
          markers.add(
            Marker(
              width: 110,
              height: 60,
              point: item.displayPos,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedOrder = order);
                  _showOrderBottomSheet(context, order);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              priceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomPaint(
                      size: const Size(10, 5),
                      painter: _TrianglePainter(
                        color: isSelected ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primaryDark : AppColors.primary,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
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
    }

    final centerPoint = widget.userCenter ?? _tashkentCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: 13.5,
            minZoom: 9.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (camera, hasGesture) {
              final newZoom = camera.zoom;
              if ((newZoom - _currentZoom).abs() > 0.35) {
                setState(() => _currentZoom = newZoom);
              }
            },
          ),
          children: [
            // Google Maps Tile Layer
            TileLayer(
              urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              subdomains: const ['0', '1', '2', '3'],
              userAgentPackageName: 'com.yaqin.findix',
              panBuffer: 1,
              keepBuffer: 3,
              maxZoom: 19,
            ),
            if (areaCircles.isNotEmpty) CircleLayer(circles: areaCircles),
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
    final bool hasBranch = (order['branch_id'] != null && order['branch_id'].toString().isNotEmpty) ||
        (order['branch_name'] != null && order['branch_name'].toString().isNotEmpty);
    final isCompanyOrder = (client != null && client['account_type'] == 'company') ||
        order['account_type'] == 'company' ||
        order['is_company'] == true ||
        order['company_logo'] != null ||
        hasBranch;

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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
                            AppStrings.isRu ? 'Официальная вакансия' : 'Rasmiy vakansiya',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Builder(builder: (_) {
                      final postedBy = (order['posted_by'] ?? '').toString();
                      final cl = order['client'];
                      final isAdm = postedBy == 'admin' || (cl != null && cl['managed_branch'] != null);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdm ? Colors.blue.withValues(alpha: 0.12) : const Color(0xFF00A651).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAdm ? Colors.blue.withValues(alpha: 0.3) : const Color(0xFF00A651).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isAdm ? (AppStrings.isRu ? '👤 Опубликовал: Админ филиала' : '👤 Joyladi: Filial admini') : (AppStrings.isRu ? '🏢 Опубликовал: Компания (Сам)' : '🏢 Joyladi: Kompaniya (O\'zi)'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdm ? Colors.blue.shade700 : const Color(0xFF00A651),
                          ),
                        ),
                      );
                    }),
                  ],
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
          // If we have branchId / branchName / clientId, fetch all refreshed open vacancies for this branch
          if (widget.apiService != null && !hasRequestedAll) {
            hasRequestedAll = true;
            final branchId = order['branch_id']?.toString();
            final branchName = order['branch_name']?.toString();
            final queryBranch = (branchId != null && branchId.isNotEmpty) ? branchId : branchName;

            if (queryBranch != null && queryBranch.isNotEmpty) {
              widget.apiService!.getAvailableOrders(branchId: queryBranch).then((branchOrders) {
                if (branchOrders.isNotEmpty && modalContext.mounted) {
                  setModalState(() {
                    activeCompanyOrders = branchOrders;
                  });
                }
              }).catchError((_) {});
            } else if (clientId != null) {
              widget.apiService!.getAvailableOrders(clientId: clientId).then((allOrders) {
                if (allOrders.isNotEmpty && modalContext.mounted) {
                  setModalState(() {
                    activeCompanyOrders = allOrders;
                  });
                }
              }).catchError((_) {});
            }
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
                              branchId: order['branch_id']?.toString(),
                              branchName: order['branch_name']?.toString(),
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
                  if (order['branch_name'] != null && order['branch_name'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store_mall_directory_rounded, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AppStrings.isRu ? "Филиал: " : "Filial: "}${order['branch_name']}${order['branch_address'] != null && order['branch_address'].toString().isNotEmpty ? " • ${order['branch_address']}" : ""}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 10),

                  // Vacancies Title
                  Row(
                    children: [
                      const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${order['branch_name'] != null && order['branch_name'].toString().isNotEmpty ? (AppStrings.isRu ? "Вакансии филиала" : "Filial vakansiyalari") : (AppStrings.isRu ? "Открытые вакансии" : "Ochiq vakansiyalar")} (${activeCompanyOrders.length})',
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
                              const SizedBox(height: 6),
                              Builder(builder: (_) {
                                final postedBy = (item['posted_by'] ?? '').toString();
                                final cl = item['client'];
                                final isAdm = postedBy == 'admin' || (cl != null && cl['managed_branch'] != null) || (cl != null && cl['role'] == 'branch_admin');
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAdm ? Colors.blue.withValues(alpha: 0.12) : const Color(0xFF00A651).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isAdm ? Colors.blue.withValues(alpha: 0.3) : const Color(0xFF00A651).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAdm ? Icons.person_pin_rounded : Icons.business_rounded,
                                        size: 13,
                                        color: isAdm ? Colors.blue.shade700 : const Color(0xFF00A651),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAdm
                                            ? (AppStrings.isRu ? '👤 Опубликовал: Админ филиала' : '👤 Joyladi: Filial admini')
                                            : (AppStrings.isRu ? '🏢 Опубликовал: Компания (Сам)' : '🏢 Joyladi: Kompaniya (O\'zi)'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isAdm ? Colors.blue.shade700 : const Color(0xFF00A651),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
