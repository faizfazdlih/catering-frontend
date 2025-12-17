// widgets/inline_map_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'enhanced_map_picker.dart';

class InlineMapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final double height;

  const InlineMapPicker({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.height = 300,
  }) : super(key: key);

  @override
  State<InlineMapPicker> createState() => _InlineMapPickerState();
}

class _InlineMapPickerState extends State<InlineMapPicker> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;

  // Default location dari .env backend: -6.8981606442658325, 107.6357241657175
  static const LatLng _defaultLocation = LatLng(-6.8981606442658325, 107.6357241657175);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? _defaultLocation;
  }

  @override
  void didUpdateWidget(InlineMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation && 
        widget.initialLocation != null) {
      setState(() {
        _selectedLocation = widget.initialLocation;
      });
      // Move map to new location
      _mapController.move(widget.initialLocation!, _mapController.camera.zoom);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    widget.onLocationSelected(latLng);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Aktifkan di pengaturan.');
      }

      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Mencari lokasi Anda dengan akurat...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Strategy 1: Try high accuracy with short timeout (fast)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Strategy 2: Fallback to medium accuracy (more reliable)
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e2) {
          // Strategy 3: Try low accuracy
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 15),
            );
          } catch (e3) {
            // Strategy 4: Use last known location as last resort (skip on web)
            try {
              position = await Geolocator.getLastKnownPosition();
            } catch (platformError) {
              // Not supported on web platform
              position = null;
            }
            
            if (position == null) {
              throw Exception('Tidak dapat menemukan lokasi.\nPastikan:\n• GPS/lokasi device aktif\n• Izinkan akses lokasi di browser\n• Berada di area dengan sinyal GPS');
            }
          }
        }
      }

      final currentLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = currentLocation;
        _isLoadingLocation = false;
      });

      // Move map to current location with higher zoom
      _mapController.move(currentLocation, 17.0);
      
      // Notify parent
      widget.onLocationSelected(currentLocation);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lokasi ditemukan! Akurasi: ${position.accuracy.toStringAsFixed(0)}m',
                  ),
                ),
              ],
            ),
            backgroundColor: position.accuracy <= 50 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gagal mendapatkan lokasi: ${e.toString()}'),
                const SizedBox(height: 4),
                const Text(
                  'Tips: Aktifkan GPS, pastikan di luar ruangan, dan coba lagi',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _openFullscreenMap() async {
    // Default restaurant/catering location (ganti dengan lokasi resto Anda)
    // Lokasi resto dari .env backend
    const LatLng restaurantLocation = LatLng(-6.8981606442658325, 107.6357241657175);
    
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMapPicker(
          initialLocation: _selectedLocation,
          title: 'Pilih Lokasi Pengiriman',
          originLocation: restaurantLocation, // Pass restaurant location for route
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      widget.onLocationSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? _defaultLocation,
                initialZoom: 15.0,
                onTap: _onMapTap,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.catering_client',
                  maxZoom: 19,
                  minZoom: 3,
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 60,
                        height: 60,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Info banner at the top
            Positioned(
              top: 8,
              left: 8,
              right: 60, // Leave space for buttons
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedLocation == null ? Icons.info_outline : Icons.location_on,
                          color: _selectedLocation == null ? Colors.blue : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLocation == null 
                              ? 'Ketuk peta atau tombol 📍'
                              : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Fullscreen button at top right
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openFullscreenMap,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.fullscreen,
                        size: 22,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Zoom and location controls at bottom right
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GPS Button - Get Current Location
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _isLoadingLocation ? null : _getCurrentLocation,
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Zoom In
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.black87, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Zoom Out
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          child: const Center(
                            child: Icon(Icons.remove, color: Colors.black87, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Center to Selected Location (only show if location selected)
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _mapController.move(_selectedLocation!, 17.0);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(10),
                            child: const Center(
                              child: Icon(
                                Icons.center_focus_strong,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
