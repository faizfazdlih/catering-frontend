// client/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/menu.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/cart_provider.dart';
import '../../utils/format_helper.dart';
import 'cart_screen.dart';
import 'pesanan_screen.dart';
import 'about_screen.dart';
import '../../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<Menu> _menuList = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'box', 'tumpeng', 'snack'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMenu();
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

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMenu();
      setState(() {
        _menuList = data.map((json) => Menu.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat menu: ${e.toString()}')),
        );
      }
    }
  }

  List<Menu> get _filteredMenu {
    if (_selectedCategory == 'Semua') {
      return _menuList;
    }
    return _menuList.where((menu) => menu.kategori == _selectedCategory).toList();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

  void _showMenuDetail(Menu menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuDetailBottomSheet(menu: menu),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catering App'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              accountName: Text(_currentUser?.nama ?? 'User'),
              accountEmail: Text(_currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.orange),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Pesanan Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PesananScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Tentang'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenu,
        child: Column(
          children: [
            // Category Filter
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Menu Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMenu.isEmpty
                      ? const Center(
                          child: Text('Tidak ada menu tersedia'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredMenu.length,
                          itemBuilder: (context, index) {
                            final menu = _filteredMenu[index];
                            final isInCart = cart.isInCart(menu.id);
                            
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _showMenuDetail(menu),
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image placeholder
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 50,
                                          color: Colors.orange.shade300,
                                        ),
                                      ),
                                    ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.namaMenu,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            FormatHelper.formatCurrency(menu.harga),
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                cart.addItem(menu);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${menu.namaMenu} ditambahkan ke keranjang'),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    isInCart ? Icons.check : Icons.add_shopping_cart,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isInCart ? 'Di Keranjang' : 'Tambah',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Detail Bottom Sheet Widget
class MenuDetailBottomSheet extends StatefulWidget {
  final Menu menu;

  const MenuDetailBottomSheet({Key? key, required this.menu}) : super(key: key);

  @override
  State<MenuDetailBottomSheet> createState() => _MenuDetailBottomSheetState();
}

class _MenuDetailBottomSheetState extends State<MenuDetailBottomSheet> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // Add multiple items based on quantity
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(widget.menu);
    }
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.menu.namaMenu} ($_quantity) ditambahkan ke keranjang'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'LIHAT',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isInCart = cart.isInCart(widget.menu.id);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 100,
                            color: Colors.orange.shade300,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Menu Name
                      Text(
                        widget.menu.namaMenu,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category Badge
                      if (widget.menu.kategori != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.menu.kategori!.toUpperCase(),
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Price
                      Text(
                        FormatHelper.formatCurrency(widget.menu.harga),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Title
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        widget.menu.deskripsi ?? 'Tidak ada deskripsi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status
                      Row(
                        children: [
                          Icon(
                            widget.menu.status == 'tersedia' 
                                ? Icons.check_circle 
                                : Icons.cancel,
                            color: widget.menu.status == 'tersedia' 
                                ? Colors.green 
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.menu.status == 'tersedia' 
                                ? 'Tersedia' 
                                : 'Habis',
                            style: TextStyle(
                              color: widget.menu.status == 'tersedia' 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      if (isInCart) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shopping_cart, 
                                color: Colors.green.shade700, 
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${cart.getQuantity(widget.menu.id)} item di keranjang',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quantity Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Jumlah:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Minus Button
                          IconButton(
                            onPressed: _decrementQuantity,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.orange,
                            iconSize: 32,
                          ),
                          
                          // Quantity Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Plus Button
                          IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add_circle),
                            color: Colors.orange,
                            iconSize: 32,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Subtotal: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            FormatHelper.formatCurrency(widget.menu.harga * _quantity),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: widget.menu.status == 'tersedia' 
                              ? _addToCart 
                              : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 24),
                          label: Text(
                            widget.menu.status == 'tersedia'
                                ? 'Tambah ke Keranjang'
                                : 'Menu Habis',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.menu.status == 'tersedia'
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}