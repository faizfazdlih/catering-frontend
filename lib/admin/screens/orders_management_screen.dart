// admin/screens/orders_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/pesanan.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';
import 'order_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import 'menu_management_screen.dart';
import 'users_management_screen.dart';
import 'admin_about_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const OrdersManagementScreen({Key? key, this.onBackPressed}) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  List<Pesanan> _pesananList = [];
  List<Pesanan> _filteredList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Semua', 'value': 'Semua', 'icon': Icons.all_inbox_rounded},
    {'label': 'Pending', 'value': 'pending', 'icon': Icons.schedule_rounded},
    {'label': 'Diproses', 'value': 'diproses', 'icon': Icons.autorenew_rounded},
    {'label': 'Dikirim', 'value': 'dikirim', 'icon': Icons.local_shipping_rounded},
    {'label': 'Selesai', 'value': 'selesai', 'icon': Icons.check_circle_rounded},
    {'label': 'Dibatalkan', 'value': 'dibatalkan', 'icon': Icons.close_rounded},
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
          SnackBar(
            content: Text('Gagal memuat pesanan: ${e.toString()}'),
            backgroundColor: const Color(0xFF9E090F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _filterPesanan() {
    setState(() {
      var filtered = _pesananList;

      // Apply status filter
      if (_selectedFilter != 'Semua') {
        filtered = filtered.where((p) => p.status == _selectedFilter).toList();
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((p) {
          final searchLower = _searchQuery.toLowerCase();
          return p.id.toString().contains(searchLower) ||
                 p.userId.toString().contains(searchLower);
        }).toList();
      }

      _filteredList = filtered;
    });
  }

  Future<void> _updateStatus(Pesanan pesanan, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Update Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Ubah status pesanan #${pesanan.id} menjadi "${_getStatusText(newStatus)}"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Update'),
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
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          _loadPesanan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: const Color(0xFF9E090F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFF9E090F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'diproses':
        return const Color(0xFF3B82F6);
      case 'dikirim':
        return const Color(0xFF8B5CF6);
      case 'selesai':
        return const Color(0xFF10B981);
      case 'dibatalkan':
        return const Color(0xFFEF4444);
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'diproses':
        return Icons.autorenew_rounded;
      case 'dikirim':
        return Icons.local_shipping_rounded;
      case 'selesai':
        return Icons.check_circle_rounded;
      case 'dibatalkan':
        return Icons.close_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF9E090F),
        backgroundColor: Colors.white,
        onRefresh: _loadPesanan,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _filterPesanan();
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari pesanan (ID atau Customer ID)...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Filter Chips
                  SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        final filter = _filterOptions[index];
                        final isSelected = filter['value'] == _selectedFilter;
                        
                        // Count pesanan for each filter
                        final count = filter['value'] == 'Semua'
                            ? _pesananList.length
                            : _pesananList.where((p) => p.status == filter['value']).length;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              filter['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            label: Text('${filter['label']} ($count)'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter['value'];
                                _filterPesanan();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF9E090F),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF9E090F) : Colors.grey[300]!,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E090F)),
                      ),
                    ),
                  )
                : _filteredList.isEmpty
                    ? SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Pesanan tidak ditemukan'
                                  : _selectedFilter == 'Semua'
                                      ? 'Belum ada pesanan'
                                      : 'Tidak ada pesanan ${_getStatusText(_selectedFilter).toLowerCase()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Coba kata kunci lain'
                                  : 'Pesanan akan muncul di sini',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final pesanan = _filteredList[index];
                              return _buildOrderCard(pesanan);
                            },
                            childCount: _filteredList.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Pesanan pesanan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStatusColor(pesanan.status),
                                _getStatusColor(pesanan.status).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(pesanan.status),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan #${pesanan.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Customer ID: ${pesanan.userId}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pesanan.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(pesanan.status),
                      style: TextStyle(
                        color: _getStatusColor(pesanan.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Order Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today_rounded,
                      'Tanggal',
                      FormatHelper.formatDateShort(
                        DateTime.parse(pesanan.tanggalPesan),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time_rounded,
                      'Waktu',
                      pesanan.waktuPengiriman != null
                          ? FormatHelper.formatTime(pesanan.waktuPengiriman!)
                          : '-',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.shopping_bag_rounded,
                      'Item',
                      '${pesanan.jumlahItem ?? 0} item',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.payments_rounded,
                      'Total',
                      FormatHelper.formatCurrency(pesanan.totalHarga),
                      valueColor: const Color(0xFF9E090F),
                      isBold: true,
                    ),
                  ),
                ],
              ),
              
              // Quick Actions
              if (pesanan.status != 'selesai' && pesanan.status != 'dibatalkan') ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildQuickActions(pesanan),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(Pesanan pesanan) {
    if (pesanan.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(pesanan, 'diproses'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Proses'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(pesanan, 'dibatalkan'),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Batalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (pesanan.status == 'diproses') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(pesanan, 'dikirim'),
              icon: const Icon(Icons.local_shipping_rounded, size: 18),
              label: const Text('Kirim Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(pesanan, 'dibatalkan'),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Batalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (pesanan.status == 'dikirim') {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF8B5CF6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Menunggu konfirmasi penerimaan dari customer',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}