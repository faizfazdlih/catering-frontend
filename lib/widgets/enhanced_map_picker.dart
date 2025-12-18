// widgets/enhanced_map_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EnhancedMapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;
  final LatLng? originLocation; // Lokasi resto/catering

  const EnhancedMapPicker({
    Key? key,
    this.initialLocation,
    this.title = 'Pilih Lokasi Pengiriman',
    this.originLocation,
  }) : super(key: key);

  @override
  State<EnhancedMapPicker> createState() => _EnhancedMapPickerState();
}

class _EnhancedMapPickerState extends State<EnhancedMapPicker> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _showRoute = false;
  List<LatLng> _routePoints = []; // Route polyline points
  
  List<Map<String, dynamic>> _placeSearchResults = []; // For Nominatim results
  Timer? _debounce;

  // Default location from backend env: -6.8981606442658325, 107.6357241657175
  static const LatLng _defaultLocation = LatLng(-6.8981606442658325, 107.6357241657175);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    
    if (_selectedLocation != null) {
      _getAddressFromCoordinates(_selectedLocation!);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      // Use Nominatim reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CateringApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Lokasi terpilih';
        });
      } else {
        setState(() {
          _selectedAddress = 'Lokasi terpilih';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Lokasi terpilih';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSearchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Use Nominatim API (OpenStreetMap) for better search
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=id&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CateringApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _placeSearchResults = results.map((r) => {
            'lat': double.parse(r['lat']),
            'lon': double.parse(r['lon']),
            'display_name': r['display_name'],
            'name': r['name'] ?? r['display_name'],
          }).toList();
          _isSearching = false;
        });
      } else {
        throw Exception('Gagal mencari lokasi');
      }
    } catch (e) {
      setState(() {
        _placeSearchResults = [];
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pencarian gagal: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _searchLocation(value);
    });
  }

  void _selectSearchResult(Map<String, dynamic> place) async {
    final latLng = LatLng(place['lat'], place['lon']);
    setState(() {
      _selectedLocation = latLng;
      _selectedAddress = place['display_name'];
      _placeSearchResults = [];
      _searchController.clear();
    });
    
    _mapController.move(latLng, 16.0);
    
    // Fetch route if origin available
    if (widget.originLocation != null && _showRoute) {
      await _fetchRoute(widget.originLocation!, latLng);
    }
    
    FocusScope.of(context).unfocus();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen');
      }

      Position? position;
      
      // Strategy 1: Try high accuracy first with short timeout
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Strategy 2: Fallback to medium accuracy if high fails
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e2) {
          // Strategy 3: Try low accuracy with longer timeout
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 15),
            );
          } catch (e3) {
            // Strategy 4: Last resort - use last known location (skip on web)
            try {
              position = await Geolocator.getLastKnownPosition();
            } catch (platformError) {
              // getLastKnownPosition not supported on web
              position = null;
            }
            
            if (position == null) {
              throw Exception('Tidak dapat menemukan lokasi.\nTips:\n• Pastikan GPS/lokasi aktif\n• Izinkan akses lokasi di browser\n• Coba di luar ruangan untuk sinyal lebih baik');
            }
          }
        }
      }

      final currentLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = currentLocation;
        _isLoadingLocation = false;
      });

      _mapController.move(currentLocation, 17.0);
      await _getAddressFromCoordinates(currentLocation);

      if (mounted) {
        final accuracyColor = position.accuracy <= 20 ? Colors.green : 
                             position.accuracy <= 50 ? Colors.orange : Colors.red;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Lokasi ditemukan! Akurasi: ±${position.accuracy.toStringAsFixed(0)}m'),
            backgroundColor: accuracyColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _getAddressFromCoordinates(latLng);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih lokasi terlebih dahulu'),
        ),
      );
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    try {
      // Use OSRM (Open Source Routing Machine) for routing
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      // Fallback to straight line if routing fails
      setState(() {
        _routePoints = [from, to];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOrigin = widget.originLocation != null;
    final distance = (_selectedLocation != null && hasOrigin)
        ? _calculateDistance(widget.originLocation!, _selectedLocation!)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.black),
              onPressed: _confirmLocation,
              tooltip: 'Konfirmasi',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? widget.initialLocation ?? _defaultLocation,
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
              
              // Route line from origin to destination
              if (_showRoute && _selectedLocation != null && hasOrigin && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              
              // Markers
              MarkerLayer(
                markers: [
                  // Origin marker (Resto location)
                  if (hasOrigin)
                    Marker(
                      point: widget.originLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Resto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.store,
                            color: Colors.green,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  
                  // Selected location marker
                  if (_selectedLocation != null)
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

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat atau tempat...',
                      prefixIcon: const Icon(Icons.search, color: Colors.orange),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _placeSearchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                
                // Search Results
                if (_placeSearchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _placeSearchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _placeSearchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: Colors.orange, size: 20),
                          title: Text(
                            place['name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            place['display_name'],
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Control Buttons (Right side)
          Positioned(
            right: 16,
            bottom: _selectedLocation != null ? 200 : 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GPS Button
                _buildControlButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white, size: 22),
                  backgroundColor: Colors.green,
                  onTap: _isLoadingLocation ? null : _getCurrentLocation,
                ),
                const SizedBox(height: 10),
                
                // Toggle Route Button
                if (hasOrigin && _selectedLocation != null)
                  _buildControlButton(
                    icon: Icon(
                      _showRoute ? Icons.route : Icons.directions,
                      color: Colors.white,
                      size: 22,
                    ),
                    backgroundColor: _showRoute ? Colors.blue : Colors.grey,
                    onTap: () async {
                      setState(() => _showRoute = !_showRoute);
                      if (_showRoute && _routePoints.isEmpty) {
                        await _fetchRoute(widget.originLocation!, _selectedLocation!);
                      }
                    },
                  ),
                if (hasOrigin && _selectedLocation != null)
                  const SizedBox(height: 10),
                
                // Zoom In
                _buildControlButton(
                  icon: const Icon(Icons.add, size: 22),
                  backgroundColor: Colors.white,
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                
                // Zoom Out
                _buildControlButton(
                  icon: const Icon(Icons.remove, size: 22),
                  backgroundColor: Colors.white,
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Info Panel
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi Pengiriman',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress.isNotEmpty
                                    ? _selectedAddress
                                    : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (hasOrigin && distance > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Jarak: ${distance.toStringAsFixed(2)} km dari resto',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Konfirmasi Lokasi',
                              style: TextStyle(
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(10),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
