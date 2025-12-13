// admin/screens/admin_about_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminAboutScreen extends StatefulWidget {
  const AdminAboutScreen({Key? key}) : super(key: key);

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  Map<String, dynamic>? _apiInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiInfo();
  }

  Future<void> _loadApiInfo() async {
    try {
      final info = await ApiService.getOngkirInfo();
      setState(() {
        _apiInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Catering Admin Panel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Versi 1.0.0',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sistem manajemen catering untuk mengelola users, menu, dan pesanan. Panel admin memudahkan proses approve customer, update menu, dan tracking pesanan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Admin Features
            const Text(
              'Fitur Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.people,
                    'Kelola Users',
                    'Approve/reject registrasi customer baru',
                  ),
                  const Divider(height: 1),
                  _buildFeatureItem(
                    Icons.restaurant_menu,
                    'Kelola Menu',
                    'CRUD menu catering dan update status',
                  ),
                  const Divider(height: 1),
                  _buildFeatureItem(
                    Icons.shopping_bag,
                    'Kelola Pesanan',
                    'Update status pesanan dari pending hingga selesai',
                  ),
                  const Divider(height: 1),
                  _buildFeatureItem(
                    Icons.analytics,
                    'Dashboard Statistik',
                    'Monitor total pesanan dan pendapatan',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // API Information
            const Text(
              'API yang Digunakan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_apiInfo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.api, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _apiInfo!['api_name'] ?? 'Ongkir API',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Deskripsi', _apiInfo!['description'] ?? '-'),
                      _buildInfoRow('Website', _apiInfo!['website'] ?? '-'),
                      _buildInfoRow('Penggunaan', _apiInfo!['usage'] ?? '-'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'API ini digunakan customer untuk menghitung ongkos kirim berdasarkan jarak pengiriman',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
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
            
            // Tech Stack
            const Text(
              'Teknologi yang Digunakan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTechItem('Frontend', 'Flutter'),
                    _buildTechItem('Backend', 'Node.js + Express.js'),
                    _buildTechItem('Database', 'MySQL'),
                    _buildTechItem('Public API', 'Ongkir Calculation'),
                    _buildTechItem('Architecture', 'Client-Server + REST API'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // System Info
            const Text(
              'Informasi Sistem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTechItem('Version', '1.0.0'),
                    _buildTechItem('Build', 'Production'),
                    _buildTechItem('Backend URL', ApiService.baseUrl),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Developer Info
            const Text(
              'Developer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.group, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tim Pengembang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Institut Teknologi Nasional Bandung',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Program Studi Informatika',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UTS Pemrograman Mobile',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Semester Ganjil 2024/2025',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Admin Credentials Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Credentials',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Username: admin'),
                    const Text('Password: admin123'),
                    const SizedBox(height: 8),
                    Text(
                      'Ganti password default untuk keamanan production',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Copyright
            Center(
              child: Text(
                '© 2024 Catering App. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(description),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}