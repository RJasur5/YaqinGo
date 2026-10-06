import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
import '../models/master.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../utils/formatters.dart';

class MasterMapView extends StatefulWidget {
  final List<MasterModel> masters;
  final Function(MasterModel) onMasterTap;
  final LatLng? userCenter;
  final Function(bool isNearby)? onNearbyToggled;

  const MasterMapView({
    super.key,
    required this.masters,
    required this.onMasterTap,
    this.userCenter,
    this.onNearbyToggled,
  });

  @override
  State<MasterMapView> createState() => _MasterMapViewState();
}

class _MasterMapViewState extends State<MasterMapView> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  MasterModel? _selectedMaster;
  late AnimationController _pulseController;

  // Nearby mode
  bool _nearbyMode = false;
  bool _nearbyLoading = false;
  double? _userLat;
  double? _userLon;
  static const double _nearbyRadiusKm = 2.0;

  static const LatLng _tashkentCenter = LatLng(41.2995, 69.2401);

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
      // Center map on user
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
  void didUpdateWidget(covariant MasterMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userCenter != null && widget.userCenter != oldWidget.userCenter) {
      _mapController.move(widget.userCenter!, 14.0);
    }
  }

  LatLng _getMasterCoordinates(MasterModel master, int index) {
    if (master.latitude != null && master.longitude != null) {
      return LatLng(master.latitude!, master.longitude!);
    }
    final double latOffset = (((master.id * 17) % 50) - 25) * 0.003;
    final double lonOffset = (((master.id * 31) % 50) - 25) * 0.004;
    return LatLng(
      _tashkentCenter.latitude + latOffset,
      _tashkentCenter.longitude + lonOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply nearby filter if active (strict 3.0 km radius)
    final visibleMasters = (_nearbyMode && _userLat != null && _userLon != null)
        ? widget.masters.where((m) {
            final idx = widget.masters.indexOf(m);
            final pos = _getMasterCoordinates(m, idx);
            return _distanceKm(_userLat!, _userLon!, pos.latitude, pos.longitude) <= _nearbyRadiusKm;
          }).toList()
        : widget.masters;

    final markers = <Marker>[];

    // User Location Marker when nearby mode is active
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
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < visibleMasters.length; i++) {
      final master = visibleMasters[i];
      final pos = _getMasterCoordinates(master, i);
      final isSelected = _selectedMaster?.id == master.id;

      markers.add(
        Marker(
          width: isSelected ? 95 : 80,
          height: isSelected ? 95 : 80,
          point: pos,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMaster = master;
              });
              _showMasterBottomSheet(context, master);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Master Avatar Pin
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : theme.cardTheme.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? Colors.white : AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: isSelected ? 24 : 20,
                      backgroundColor: AppColors.primary,
                      backgroundImage: (master.userAvatar != null && master.userAvatar!.isNotEmpty)
                          ? ResizeImage(
                              NetworkImage(
                                master.userAvatar!.startsWith('http')
                                    ? master.userAvatar!
                                    : '${ApiConfig.baseUrl.replaceAll("/api", "")}${master.userAvatar}',
                              ),
                              width: 80,
                              height: 80,
                            )
                          : null,
                      child: (master.userAvatar == null || master.userAvatar!.isEmpty)
                          ? Text(
                              master.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          master.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
              urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              subdomains: const ['0', '1', '2', '3'],
              userAgentPackageName: 'com.yaqin.findix',
              panBuffer: 1,
              keepBuffer: 3,
              maxZoom: 19,
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


  void _showMasterBottomSheet(BuildContext context, MasterModel master) {
    final theme = Theme.of(context);

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
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: (master.userAvatar != null && master.userAvatar!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              master.userAvatar!.startsWith('http')
                                  ? master.userAvatar!
                                  : '${ApiConfig.baseUrl.replaceAll("/api", "")}${master.userAvatar}',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              master.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          master.userName.capitalizeWords(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          master.subcategoryName(AppStrings.lang),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${master.rating.toStringAsFixed(1)} (${master.reviewsCount})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (master.city != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                                  const SizedBox(width: 2),
                                  Text(
                                    master.city!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (master.hourlyRate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${master.experienceYears} ${AppStrings.years}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${PriceFormatter.format(master.hourlyRate)} ${AppStrings.sum}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onMasterTap(master);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppStrings.isRu ? 'Открыть профиль' : 'Profilni ochish',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
