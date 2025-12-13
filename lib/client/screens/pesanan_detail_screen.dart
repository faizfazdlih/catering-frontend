// screens/pesanan_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/pesanan.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';

class PesananDetailScreen extends StatefulWidget {
  final int pesananId;

  const PesananDetailScreen({Key? key, required this.pesananId}) : super(key: key);

  @override
  State<PesananDetailScreen> createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends State<PesananDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getPesananDetail(widget.pesananId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail: ${e.toString()}')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return Colors.blue;
      case 'dikirim':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'diproses':
        return 'Sedang Diproses';
      case 'dikirim':
        return 'Sedang Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Card(
                        color: _getStatusColor(_data!['pesanan']['status']),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Status Pesanan',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      _getStatusText(_data!['pesanan']['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Order Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Pesanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow('No. Pesanan', '#${_data!['pesanan']['id']}'),
                              _buildInfoRow(
                                'Tanggal Pesan',
                                FormatHelper.formatDateWithMonth(
                                  DateTime.parse(_data!['pesanan']['tanggal_pesan']),
                                ),
                              ),
                              _buildInfoRow(
                                'Waktu Pengiriman', 
                                _data!['pesanan']['waktu_pengiriman'] != null
                                  ? FormatHelper.formatTime(_data!['pesanan']['waktu_pengiriman'])
                                  : '-'
                              ),
                              _buildInfoRow('Alamat', _data!['pesanan']['alamat_pengiriman']),
                              if (_data!['pesanan']['catatan'] != null)
                                _buildInfoRow('Catatan', _data!['pesanan']['catatan']),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Items
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daftar Menu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              ...(_data!['detail'] as List).map((item) {
                                final detail = PesananDetail.fromJson(item);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Colors.orange.shade300,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detail.namaMenu ?? 'Menu',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${FormatHelper.formatCurrency(detail.hargaSatuan)} x ${detail.jumlah}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        FormatHelper.formatCurrency(detail.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rincian Pembayaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              
                              // Calculate subtotal from items
                              Builder(
                                builder: (context) {
                                  double subtotal = 0;
                                  for (var item in _data!['detail']) {
                                    subtotal += double.parse(item['subtotal'].toString());
                                  }
                                  
                                  final ongkir = _data!['pesanan']['ongkir'] != null
                                      ? double.parse(_data!['pesanan']['ongkir'].toString())
                                      : 0.0;
                                  final total = double.parse(_data!['pesanan']['total_harga'].toString());
                                  
                                  return Column(
                                    children: [
                                      _buildPaymentRow('Subtotal', FormatHelper.formatCurrency(subtotal)),
                                      _buildPaymentRow('Ongkos Kirim', FormatHelper.formatCurrency(ongkir)),
                                      if (_data!['pesanan']['jarak_km'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Jarak: ${_data!['pesanan']['jarak_km']} km',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            FormatHelper.formatCurrency(total),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}