// admin/screens/orders_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/pesanan.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';
import 'order_detail_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  List<Pesanan> _pesananList = [];
  List<Pesanan> _filteredList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'pending',
    'diproses',
    'dikirim',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _loadPesanan();
  }

  Future<void> _loadPesanan() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getAllPesanan();
      setState(() {
        _pesananList = data.map((json) => Pesanan.fromJson(json)).toList();
        _filterPesanan();
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

  void _filterPesanan() {
    if (_selectedFilter == 'Semua') {
      _filteredList = _pesananList;
    } else {
      _filteredList = _pesananList
          .where((pesanan) => pesanan.status == _selectedFilter)
          .toList();
    }
  }

  Future<void> _updateStatus(Pesanan pesanan, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text(
          'Ubah status pesanan #${pesanan.id} menjadi "$newStatus"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.updatePesananStatus(pesanan.id, newStatus);
      
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadPesanan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
        return 'Pending';
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
        title: const Text('Kelola Pesanan'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPesanan,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = filter == _selectedFilter;
                  
                  // Count pesanan for each filter
                  final count = filter == 'Semua'
                      ? _pesananList.length
                      : _pesananList.where((p) => p.status == filter).length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('$filter ($count)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _filterPesanan();
                        });
                      },
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'Semua'
                                  ? 'Belum ada pesanan'
                                  : 'Tidak ada pesanan $_selectedFilter',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPesanan,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final pesanan = _filteredList[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailScreen(
                                        pesananId: pesanan.id,
                                      ),
                                    ),
                                  ).then((_) => _loadPesanan());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pesanan #${pesanan.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Customer ID: ${pesanan.userId}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
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
                                      const SizedBox(height: 12),
                                      
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
                                          const Spacer(),
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
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Quick Actions
                                      if (pesanan.status != 'selesai' && pesanan.status != 'dibatalkan')
                                        Row(
                                          children: [
                                            if (pesanan.status == 'pending')
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _updateStatus(pesanan, 'diproses'),
                                                  icon: const Icon(Icons.play_arrow, size: 16),
                                                  label: const Text('Proses', style: TextStyle(fontSize: 12)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            
                                            if (pesanan.status == 'diproses') ...[
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _updateStatus(pesanan, 'dikirim'),
                                                  icon: const Icon(Icons.local_shipping, size: 16),
                                                  label: const Text('Kirim', style: TextStyle(fontSize: 12)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            
                                            if (pesanan.status == 'dikirim') ...[
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateStatus(pesanan, 'selesai'),
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: const Text('Selesai', style: TextStyle(fontSize: 12)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            
                                            if (pesanan.status == 'pending' || pesanan.status == 'diproses') ...[
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _updateStatus(pesanan, 'dibatalkan'),
                                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                                  label: const Text(
                                                    'Batalkan',
                                                    style: TextStyle(fontSize: 12, color: Colors.red),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            ],
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
          ),
        ],
      ),
    );
  }
}