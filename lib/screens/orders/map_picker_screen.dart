import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? initialLandmark;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialLandmark,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(41.2995, 69.2401); // Tashkent Default
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (widget.initialLat != null && widget.initialLon != null) {
      _center = LatLng(widget.initialLat!, widget.initialLon!);
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      _center = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: ');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(AppStrings.isRu ? 'Выбор места' : 'Joylashuvni tanlash', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _center.latitude,
                'lon': _center.longitude,
                
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(AppStrings.isRu ? 'Готово' : 'Tayyor', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 14.0,
                          onPositionChanged: (position, hasGesture) {
                            if (hasGesture && position.center != null) {
                              setState(() {
                                _center = position.center!;
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
                        ],
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.location_on, size: 40, color: Colors.red),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          heroTag: 'my_loc',
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.blue),
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await _initLocation();
                            _mapController.move(_center, 15.0);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
    );
  }
}
