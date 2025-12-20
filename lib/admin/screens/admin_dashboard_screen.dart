// admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';
import '../../models/user.dart';
import '../../main.dart';
import 'users_management_screen.dart';
import 'menu_management_screen.dart';
import 'orders_management_screen.dart';
import 'admin_about_screen.dart';
import '../../screens/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  User? _currentUser;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;
  
  // Chart data
  List<dynamic> _chartData = [];
  bool _isLoadingChart = false;
  String _selectedPeriod = 'today';
  late AnimationController _chartAnimationController;
  Animation<double>? _chartFadeAnimation;
  Animation<Offset>? _chartSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _chartFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _chartSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
    
    // Load chart data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChartData(_selectedPeriod);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        _currentUser = User.fromJson(jsonDecode(userJson));
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final stats = await ApiService.getStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat statistik: ${e.toString()}',
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

  Future<void> _loadChartData(String period) async {
    setState(() => _isLoadingChart = true);

    try {
      final chartData = await ApiService.getChartData(period);
      
      setState(() {
        _chartData = chartData;
        _selectedPeriod = period;
        _isLoadingChart = false;
      });
      // Trigger animation after data loaded
      _chartAnimationController.reset();
      _chartAnimationController.forward();
    } catch (e) {
      setState(() => _isLoadingChart = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat data chart: ${e.toString()}',
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar?'),
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _showAdminDialog() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        20,
        kToolbarHeight + MediaQuery.of(context).padding.top + 10,
        MediaQuery.of(context).size.width - 280,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      color: Colors.white,
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.nama ?? 'Administrator',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.email ?? 'admin@catering.com',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF636E72),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
            ],
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.logout,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showStatDetail(String title, String value, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9E090F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        color: const Color(0xFF000000),
        backgroundColor: Colors.white,
        onRefresh: _loadStatistics,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          slivers: [
            // Header with User Icon (EXACTLY like home_screen)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Icon
                    GestureDetector(
                      onTap: _showAdminDialog,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF9E090F),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Empty space (no cart in admin)
                    SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),

            // Statistics Section with 2x2 Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistik',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 2x2 Grid Stats Cards
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E090F)),
                            ),
                          )
                        : Column(
                            children: [
                              // Row 1
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Orders',
                                      '${_stats['total_pesanan'] ?? 0}',
                                      Icons.shopping_bag_outlined,
                                      const Color(0xFF9E090F),
                                      const Color(0xFFFFF5F5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Pending',
                                      '${_stats['pesanan_pending'] ?? 0}',
                                      Icons.schedule_outlined,
                                      const Color(0xFFF59E0B),
                                      const Color(0xFFFFFBEB),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Row 2
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Today',
                                      '${_stats['pesanan_hari_ini'] ?? 0}',
                                      Icons.calendar_today_outlined,
                                      const Color(0xFF10B981),
                                      const Color(0xFFF0FDF4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Revenue',
                                      FormatHelper.formatCurrency(
                                        _parseDouble(_stats['total_pendapatan']),
                                      ),
                                      Icons.trending_up_rounded,
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFFAF5FF),
                                      isSmallText: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            // Orders Chart Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Grafik Pesanan',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPeriod == 'today'
                                  ? 'Pesanan Hari ini'
                                  : _selectedPeriod == 'weekly'
                                      ? '7 hari terakhir'
                                      : '4 minggu terakhir',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        // Filter Buttons
                        Row(
                          children: [
                            _buildFilterButton('Hari ini', 'today'),
                            const SizedBox(width: 6),
                            _buildFilterButton('Mingguan', 'weekly'),
                            const SizedBox(width: 6),
                            _buildFilterButton('Bulanan', 'monthly'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Chart Container
                    Container(
                      height: 300,
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
                      padding: const EdgeInsets.all(20),
                      child: _isLoadingChart
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E090F)),
                              ),
                            )
                          : _selectedPeriod == 'today'
                              ? _buildScrollableChart()
                              : _buildChart(),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions Header (like "Semua Makanan")
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 0)),

            // Quick Actions List (only 3 actions)
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E090F)),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildQuickActionCard(
                          icon: Icons.person_add_outlined,
                          title: 'Manage New Users',
                          subtitle: 'Approve user registrations',
                          iconColor: const Color(0xFF667EEA),
                          backgroundColor: const Color(0xFFF0F4FF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UsersManagementScreen(initialTab: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionCard(
                          icon: Icons.restaurant_outlined,
                          title: 'Add New Menu',
                          subtitle: 'Create new food items',
                          iconColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFFF0FDF4),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MenuManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Process Orders',
                          subtitle: 'Manage pending orders',
                          iconColor: const Color(0xFFF59E0B),
                          backgroundColor: const Color(0xFFFFFBEB),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrdersManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color backgroundColor, {
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallText ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
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
        child: Row(
          children: [
            // Icon Section (same as menu image section)
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 48),
                    ),
                  ),
                ],
              ),
            ),
            // Content (same as menu content)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Arrow (like menu button position)
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9E090F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  void _onNavBarTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardPage(),
      UsersManagementScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
      MenuManagementScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
      OrdersManagementScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
      const AdminAboutScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Dashboard',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.people_rounded,
                label: 'Users',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.shopping_bag_rounded,
                label: 'Orders',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.info_outline_rounded,
                label: 'About',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _loadChartData(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9E090F) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF9E090F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF9E090F).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableChart() {
    if (_chartData == null || _chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data untuk ditampilkan',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxOrders = _chartData.fold<double>(0, (max, item) {
      final orders = ((item['orders'] ?? 0) as num).toDouble();
      return orders > max ? orders : max;
    });

    final hasData = maxOrders > 0;

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: _chartFadeAnimation != null && _chartSlideAnimation != null
              ? FadeTransition(
                  opacity: _chartFadeAnimation!,
                  child: SlideTransition(
                    position: _chartSlideAnimation!,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _chartData.length * 35.0, // 35px per bar for better spacing
                        child: Stack(
                          children: [
                            BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxOrders > 0 ? (maxOrders <= 5 ? maxOrders + 2 : maxOrders * 1.2) : 10,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => const Color(0xFF2D3436),
                                    tooltipRoundedRadius: 12,
                                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final hour = _chartData[groupIndex]['label'];
                                      return BarTooltipItem(
                                        'Jam $hour\n${rod.toY.toInt()} pesanan',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < _chartData.length) {
                                          String label = _chartData[index]['label'].toString();
                                          // Show every 2 hours
                                          if (index % 2 != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10.0),
                                            child: Text(
                                              '${label}h',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 55,
                                      interval: maxOrders > 0 
                                          ? (maxOrders <= 5 
                                              ? 1.0
                                              : (maxOrders / 5).ceilToDouble().clamp(1.0, double.infinity))
                                          : 1.0,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 1 != 0) return const SizedBox.shrink();
                                        if (value < 0) return const SizedBox.shrink();
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: maxOrders > 0 
                                      ? (maxOrders <= 5 ? 1.0 : (maxOrders / 5).toDouble()).clamp(1.0, double.infinity)
                                      : 2.0,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1.5,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _chartData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final orders = ((item['orders'] ?? 0) as num).toDouble();
                                  
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: orders,
                                        color: const Color(0xFF9E090F),
                                        width: 24,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            if (!hasData)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Belum ada pesanan untuk hari ini',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
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
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_chartData == null || _chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data untuk ditampilkan',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxOrders = _chartData.fold<double>(0, (max, item) {
      final orders = ((item['orders'] ?? 0) as num).toDouble();
      return orders > max ? orders : max;
    });

    // Check if all data is zero
    final hasData = maxOrders > 0;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Chart
        Expanded(
          child: _chartFadeAnimation != null && _chartSlideAnimation != null
              ? FadeTransition(
                  opacity: _chartFadeAnimation!,
                  child: SlideTransition(
                    position: _chartSlideAnimation!,
                    child: Stack(
                      children: [
                        BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxOrders > 0 ? (maxOrders <= 5 ? maxOrders + 2 : maxOrders * 1.2) : 10,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => const Color(0xFF2D3436),
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} pesanan',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _chartData.length) {
                        String label = _chartData[index]['label'].toString();
                        // Shorten label for today view
                        if (_selectedPeriod == 'today') {
                          // Show only every 3 hours for better readability
                          if (index % 3 != 0 && index != _chartData.length - 1) {
                            return const SizedBox.shrink();
                          }
                          label = '${label}h';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 55,
                    interval: maxOrders > 0 
                        ? (maxOrders <= 5 
                            ? 1.0
                            : (maxOrders / 5).ceilToDouble().clamp(1.0, double.infinity))
                        : 1.0,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      if (value < 0) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxOrders > 0 
                    ? (maxOrders <= 5 ? 1.0 : (maxOrders / 5).toDouble()).clamp(1.0, double.infinity)
                    : 2.0,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1.5,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: _chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final orders = ((item['orders'] ?? 0) as num).toDouble();
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: orders,
                      color: const Color(0xFF9E090F),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
              if (!hasData)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Belum ada pesanan untuk periode ini',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxOrders > 0 ? maxOrders * 1.2 : 10,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavBarTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Color(0xFF9E090F) : Colors.grey[400],
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}