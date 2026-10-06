import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../config/theme.dart';
import '../config/localization.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _selectedLocation;
  String _addressText = '';

  static const LatLng _tashkentDefault = LatLng(41.2995, 69.2401);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLon!);
    } else {
      _selectedLocation = _tashkentDefault;
    }
    _addressText = widget.initialAddress ?? (AppStrings.isRu ? 'Ташкент' : 'Toshkent');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isRu ? 'Выберите локацию на карте' : 'Xaritada joylashuvni tanlang'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Maps tile layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14.5,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _selectedLocation = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.yaqin.findix',
                panBuffer: 1,
                keepBuffer: 3,
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: _selectedLocation,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Recenter to my location button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter_picker',
              backgroundColor: theme.cardTheme.color,
              foregroundColor: theme.primaryColor,
              onPressed: () {
                _mapController.move(_tashkentDefault, 14.5);
                setState(() {
                  _selectedLocation = _tashkentDefault;
                });
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
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
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.isRu ? 'Выбранная точка:' : 'Tanlangan nuqta:',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          LocationPickerResult(
                            latitude: _selectedLocation.latitude,
                            longitude: _selectedLocation.longitude,
                            address: _addressText,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        AppStrings.isRu ? 'Подтвердить локацию' : 'Joylashuvni tasdiqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
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
            ),
          ),
        ],
      ),
    );
  }
}
