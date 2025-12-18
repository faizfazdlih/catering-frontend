// admin/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/pesanan.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final int pesananId;

  const OrderDetailScreen({Key? key, required this.pesananId})
      : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  // Helper function untuk parse double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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
          SnackBar(
            content: Text(
              'Gagal memuat detail: ${e.toString()}',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(newStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(newStatus),
                color: _getStatusColor(newStatus),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Ubah status pesanan menjadi "${_getStatusText(newStatus)}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.updatePesananStatus(
        widget.pesananId,
        newStatus,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(response['message'])),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          _loadDetail();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        color: const Color(0xFF9E090F),
        backgroundColor: Colors.white,
        onRefresh: _loadDetail,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Detail Pesanan #${widget.pesananId}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            // Loading or Content
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E090F)),
                      ),
                    ),
                  )
                : _data == null
                    ? SliverFillRemaining(
                        child: Center(
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
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Data tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate([
                          // Status Hero Section
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(_data!['pesanan']['status']),
                                  _getStatusColor(_data!['pesanan']['status'])
                                      .withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Icon(
                                        _getStatusIcon(_data!['pesanan']['status']),
                                        color: Colors.white,
                                        size: 56,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _getStatusText(_data!['pesanan']['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Order ID: #${_data!['pesanan']['id']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Content Cards
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Customer Info
                                _buildModernCard(
                                  title: 'Informasi Customer',
                                  icon: Icons.person_rounded,
                                  iconColor: const Color(0xFF3B82F6),
                                  child: Column(
                                    children: [
                                      _buildModernInfoRow(
                                        icon: Icons.person_outline_rounded,
                                        label: 'Nama Customer',
                                        value: _data!['pesanan']['nama_customer'] ?? 'N/A',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernInfoRow(
                                        icon: Icons.email_outlined,
                                        label: 'Email',
                                        value: _data!['pesanan']['email'] ?? 'N/A',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernInfoRow(
                                        icon: Icons.phone_outlined,
                                        label: 'No. Telepon',
                                        value: _data!['pesanan']['no_telepon'] ?? 'N/A',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Order Info
                                _buildModernCard(
                                  title: 'Informasi Pesanan',
                                  icon: Icons.receipt_long_rounded,
                                  iconColor: const Color(0xFF8B5CF6),
                                  child: Column(
                                    children: [
                                      _buildModernInfoRow(
                                        icon: Icons.calendar_today_rounded,
                                        label: 'Tanggal Pesan',
                                        value: FormatHelper.formatDateWithMonth(
                                          DateTime.parse(_data!['pesanan']['tanggal_pesan']),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernInfoRow(
                                        icon: Icons.access_time_rounded,
                                        label: 'Waktu Pengiriman',
                                        value: _data!['pesanan']['waktu_pengiriman'] != null
                                            ? FormatHelper.formatTime(_data!['pesanan']['waktu_pengiriman'])
                                            : '-',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernInfoRow(
                                        icon: Icons.location_on_outlined,
                                        label: 'Alamat Pengiriman',
                                        value: _data!['pesanan']['alamat_pengiriman'],
                                        isMultiline: true,
                                      ),
                                      if (_data!['pesanan']['jarak_km'] != null) ...[
                                        const SizedBox(height: 16),
                                        _buildModernInfoRow(
                                          icon: Icons.social_distance_rounded,
                                          label: 'Jarak',
                                          value: '${_data!['pesanan']['jarak_km']} km',
                                        ),
                                      ],
                                      if (_data!['pesanan']['catatan'] != null) ...[
                                        const SizedBox(height: 16),
                                        _buildModernInfoRow(
                                          icon: Icons.note_outlined,
                                          label: 'Catatan',
                                          value: _data!['pesanan']['catatan'],
                                          isMultiline: true,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Menu Items
                                _buildModernCard(
                                  title: 'Daftar Menu',
                                  icon: Icons.restaurant_menu_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  child: Column(
                                    children: [
                                      ...(_data!['detail'] as List).asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final item = entry.value;
                                        final detail = PesananDetail.fromJson(item);
                                        return Column(
                                          children: [
                                            if (index > 0)
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Divider(height: 1, color: Colors.grey[200]),
                                              ),
                                            _buildMenuItem(detail),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Payment Summary
                                _buildModernCard(
                                  title: 'Rincian Pembayaran',
                                  icon: Icons.payments_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  child: Builder(
                                    builder: (context) {
                                      double subtotal = 0;
                                      for (var item in _data!['detail']) {
                                        subtotal += _parseDouble(item['subtotal']);
                                      }

                                      final ongkir = _parseDouble(_data!['pesanan']['ongkir']);
                                      final total = _parseDouble(_data!['pesanan']['total_harga']);

                                      return Column(
                                        children: [
                                          _buildPaymentRow(
                                            'Subtotal Menu',
                                            FormatHelper.formatCurrency(subtotal),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildPaymentRow(
                                            'Ongkos Kirim',
                                            FormatHelper.formatCurrency(ongkir),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 20),
                                            child: Divider(height: 1, color: Colors.grey[300]),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF9E090F).withOpacity(0.1),
                                                  const Color(0xFF9E090F).withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFF9E090F).withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total Pembayaran',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF9E090F),
                                                  ),
                                                ),
                                                Text(
                                                  FormatHelper.formatCurrency(total),
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF9E090F),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                if (_data!['pesanan']['status'] != 'selesai' &&
                                    _data!['pesanan']['status'] != 'dibatalkan') ...[
                                  _buildActionButtons(),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ),
                          ),
                        ]),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(PesananDetail detail) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withOpacity(0.2),
                const Color(0xFFF59E0B).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: Color(0xFFF59E0B),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.namaMenu ?? 'Menu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${detail.jumlah}x',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    FormatHelper.formatCurrency(detail.hargaSatuan),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          FormatHelper.formatCurrency(detail.subtotal),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _data!['pesanan']['status'];

    if (status == 'pending') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _updateStatus('diproses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'PROSES PESANAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _updateStatus('dibatalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cancel_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'BATALKAN PESANAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (status == 'diproses') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _updateStatus('dikirim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_shipping_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'KIRIM PESANAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _updateStatus('dibatalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cancel_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'BATALKAN PESANAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (status == 'dikirim') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Pesanan sedang dalam pengiriman. Menunggu konfirmasi penerimaan dari customer.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6D28D9),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
