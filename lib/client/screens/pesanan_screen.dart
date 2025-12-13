// screens/pesanan_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../models/pesanan.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';
import 'pesanan_detail_screen.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({Key? key}) : super(key: key);

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  User? _currentUser;
  List<Pesanan> _pesananList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      setState(() => _currentUser = user);
      await _loadPesanan(user.id);
    }
  }

  Future<void> _loadPesanan(int userId) async {
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getUserPesanan(userId);
      setState(() {
        _pesananList = data.map((json) => Pesanan.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: ${e.toString()}')),
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
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'dikirim':
        return 'Dikirim';
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
        title: const Text('Pesanan Saya'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pesananList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Pesanan',
                        style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pesanan Anda akan muncul di sini',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadPesanan(_currentUser!.id),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pesananList.length,
                    itemBuilder: (context, index) {
                      final pesanan = _pesananList[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PesananDetailScreen(
                                  pesananId: pesanan.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pesanan #${pesanan.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(pesanan.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(pesanan.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      FormatHelper.formatDateShort(
                                        DateTime.parse(pesanan.tanggalPesan),
                                      ),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      pesanan.waktuPengiriman != null 
                                        ? FormatHelper.formatTime(pesanan.waktuPengiriman!)
                                        : '-',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pesanan.jumlahItem ?? 0} item',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                
                                const Divider(height: 16),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      FormatHelper.formatCurrency(pesanan.totalHarga),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}