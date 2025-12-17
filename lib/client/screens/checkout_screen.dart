// screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/cart_provider.dart';
import '../../utils/format_helper.dart';
import '../../widgets/inline_map_picker.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alamatController = TextEditingController();
  final _jarakController = TextEditingController();
  final _destLatController = TextEditingController();
  final _destLngController = TextEditingController();
  final _catatanController = TextEditingController();
  double _calculatedJarak = 0;

  User? _currentUser;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _ongkir = 0;
  String _estimasiWaktu = '';
  bool _isCalculating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tryGetCurrentLocation();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      setState(() {
        _currentUser = user;
        _alamatController.text = user.alamat ?? '';
      });
    }
  }

  Future<void> _tryGetCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ GPS tidak aktif. Aktifkan GPS untuk deteksi lokasi otomatis.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // Permission denied, skip
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return; // Permission denied forever, skip
      }

      // Show loading indicator
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
                Text('🔍 Mendeteksi lokasi Anda...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 15),
          ),
        );
      }

      // Get current position with BEST accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      // If accuracy is low, try again
      if (position.accuracy > 50) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
      }

      // Auto-fill location if not already set
      if (_destLatController.text.isEmpty && _destLngController.text.isEmpty) {
        setState(() {
          _destLatController.text = position.latitude.toStringAsFixed(6);
          _destLngController.text = position.longitude.toStringAsFixed(6);
        });
        
        // Auto-calculate ongkir
        _calculateOngkir();

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 Lokasi terdeteksi! Akurasi: ${position.accuracy.toStringAsFixed(0)}m',
                    ),
                  ),
                ],
              ),
              backgroundColor: position.accuracy <= 50 ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Silent fail for auto-detect, but show message if timeout
      if (mounted && e.toString().contains('timeout')) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Timeout deteksi lokasi. Silakan pilih lokasi manual di peta.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _destLatController.text = location.latitude.toStringAsFixed(6);
      _destLngController.text = location.longitude.toStringAsFixed(6);
    });
    // Auto-calculate ongkir setelah lokasi dipilih
    _calculateOngkir();
  }

  Future<void> _calculateOngkir() async {
    // Prefer using destination coordinates so server (heigit) can compute the route
    if (_destLatController.text.isEmpty || _destLngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan koordinat tujuan (lat & lng) untuk menghitung ongkir')),
      );
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final destLat = double.tryParse(_destLatController.text);
      final destLng = double.tryParse(_destLngController.text);
      if (destLat == null || destLng == null) throw Exception('Koordinat tujuan tidak valid');

      final result = await ApiService.calculateOngkir(destination: {'lat': destLat, 'lng': destLng});

      setState(() {
        _ongkir = (result['ongkir'] as num).toDouble();
        _estimasiWaktu = result['estimasi_waktu'] ?? '';
        if (result['jarak_km'] != null) {
          _calculatedJarak = (result['jarak_km'] as num).toDouble();
          _jarakController.text = _calculatedJarak.toString();
        }
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghitung ongkir: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ongkir == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung ongkir terlebih dahulu')),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data user tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final cart = Provider.of<CartProvider>(context, listen: false);

    // Prepare items
    final items = cart.items
        .map(
          (item) => {
            'menu_id': item.menu.id,
            'jumlah': item.jumlah,
            'harga_satuan': item.menu.harga,
          },
        )
        .toList();

    try {
      final response = await ApiService.createPesanan(
        userId: _currentUser!.id,
        tanggalPesan: FormatHelper.formatDateForApi(_selectedDate),
        waktuPengiriman: FormatHelper.formatTimeForApi(
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        alamatPengiriman: _alamatController.text,
        jarakKm: double.parse(_jarakController.text),
        ongkir: _ongkir,
        items: items,
        catatan: _catatanController.text.isNotEmpty
            ? _catatanController.text
            : null,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Clear cart
        cart.clear();

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Pesanan Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text('Pesanan Anda berhasil dibuat!'),
                const SizedBox(height: 8),
                Text(
                  'Total: ${FormatHelper.formatCurrency(response['data']['total_harga'].toDouble())}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal membuat pesanan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final subtotal = cart.totalHarga;
    final total = subtotal + _ongkir;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.menu.namaMenu} x${item.jumlah}',
                                ),
                              ),
                              Text(FormatHelper.formatCurrency(item.subtotal)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            FormatHelper.formatCurrency(subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Delivery Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Pengiriman',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _alamatController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Pengiriman',
                          prefixIcon: Icon(Icons.location_on),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _jarakController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Jarak',
                          prefixIcon: const Icon(Icons.social_distance),
                          suffixIcon: _isCalculating
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          helperText: _isCalculating 
                              ? 'Menghitung jarak...' 
                              : 'Dihitung otomatis setelah pilih lokasi',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Nilai jarak tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pilih Lokasi Pengiriman di Peta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ketuk peta untuk memilih lokasi pengiriman. Ongkir akan dihitung otomatis.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Inline Map
                      InlineMapPicker(
                        height: 300,
                        initialLocation: _destLatController.text.isNotEmpty && 
                                        _destLngController.text.isNotEmpty
                            ? LatLng(
                                double.tryParse(_destLatController.text) ?? -6.914744,
                                double.tryParse(_destLngController.text) ?? 107.609810,
                              )
                            : null,
                        onLocationSelected: _onLocationSelected,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Koordinat terpilih (read-only)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _destLatController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _destLngController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      if (_ongkir > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Ongkir:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    FormatHelper.formatCurrency(_ongkir),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (_estimasiWaktu.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Estimasi waktu: $_estimasiWaktu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Tanggal Pengiriman'),
                        subtitle: Text(
                          FormatHelper.formatDateWithMonth(_selectedDate),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectDate,
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Waktu Pengiriman'),
                        subtitle: Text(_selectedTime.format(context)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectTime,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          prefixIcon: Icon(Icons.note),
                          alignLabelWithHint: true,
                          hintText: 'Contoh: Jangan terlalu pedas',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Total
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        FormatHelper.formatCurrency(total),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Memproses...' : 'Buat Pesanan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _jarakController.dispose();
    _destLatController.dispose();
    _destLngController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
}
