// screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_provider.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Set<int> selectedItems = {}; // Set untuk menyimpan ID item yang dipilih
  bool selectAll = false; // State untuk checkbox "Semua"

  // Method untuk toggle item selection
  void toggleItemSelection(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
        selectAll = false;
      } else {
        selectedItems.add(itemId);
      }
    });
  }

  // Method untuk toggle select all
  void toggleSelectAll(CartProvider cart) {
    setState(() {
      if (selectAll) {
        selectedItems.clear();
        selectAll = false;
      } else {
        selectedItems = cart.items.map((item) => item.menu.id).toSet();
        selectAll = true;
      }
    });
  }

  // Method untuk menghitung total harga item yang dipilih
  double calculateSelectedTotal(CartProvider cart) {
    double total = 0;
    for (var item in cart.items) {
      if (selectedItems.contains(item.menu.id)) {
        total += (item.menu.harga * item.jumlah).toDouble();
      }
    }
    return total;
  }

  // Method untuk menghitung jumlah item yang dipilih
  int getSelectedCount() {
    return selectedItems.length;
  }

  Widget _buildCartImage(String? fotoUrl, {double size = 80}) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          ApiService.getImageUrl(fotoUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: size * 0.5,
                color: Colors.grey[300],
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.restaurant_menu,
          size: size * 0.5,
          color: Colors.grey[300],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // Auto-update selectAll status based on selectedItems
    if (cart.items.isNotEmpty) {
      bool allSelected = cart.items.every((item) => selectedItems.contains(item.menu.id));
      if (allSelected != selectAll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              selectAll = allSelected;
            });
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Keranjang',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cart.itemCount > 0 && selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Hapus Item',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Hapus ${selectedItems.length} item yang dipilih dari keranjang?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Hapus semua item yang dipilih
                          for (var itemId in selectedItems.toList()) {
                            cart.removeItem(itemId);
                          }
                          setState(() {
                            selectedItems.clear();
                            selectAll = false;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan menu favorit Anda',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final isSelected = selectedItems.contains(item.menu.id);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF00AA13).withOpacity(0.3) 
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            GestureDetector(
                              onTap: () => toggleItemSelection(item.menu.id),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFF00AA13) 
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF00AA13) 
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Image
                            _buildCartImage(item.menu.fotoUrl, size: 80),
                            const SizedBox(width: 12),
                            
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menu.namaMenu,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.menu.kategori != null)
                                    Text(
                                      item.menu.kategori!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        FormatHelper.formatCurrency(item.menu.harga),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // Quantity controls dengan tombol delete/minus
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAFAFA),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Delete/Minus button
                                            GestureDetector(
                                              onTap: () {
                                                if (item.jumlah == 1) {
                                                  // Jika quantity = 1, tampilkan dialog konfirmasi hapus
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      title: const Text(
                                                        'Hapus Item',
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      content: Text(
                                                        'Hapus "${item.menu.namaMenu}" dari keranjang?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: Text(
                                                            'Batal',
                                                            style: TextStyle(color: Colors.grey[600]),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            cart.removeItem(item.menu.id);
                                                            setState(() {
                                                              selectedItems.remove(item.menu.id);
                                                            });
                                                            Navigator.pop(context);
                                                          },
                                                          child: const Text(
                                                            'Hapus',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else {
                                                  // Jika quantity > 1, kurangi quantity
                                                  cart.updateQuantity(
                                                    item.menu.id,
                                                    item.jumlah - 1,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Icon(
                                                  item.jumlah == 1 
                                                      ? Icons.delete_outline  // Tampilkan tong sampah jika quantity = 1
                                                      : Icons.remove,         // Tampilkan minus jika quantity > 1
                                                  size: 18,
                                                  color: item.jumlah == 1 
                                                      ? Colors.red[400]       // Warna merah untuk tong sampah
                                                      : Colors.grey[600],     // Warna abu untuk minus
                                                ),
                                              ),
                                            ),
                                            
                                            // Quantity
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 30),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${item.jumlah}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            
                                            // Increase button
                                            GestureDetector(
                                              onTap: () {
                                                cart.updateQuantity(
                                                  item.menu.id,
                                                  item.jumlah + 1,
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Total items and checkbox
                        Row(
                          children: [
                            // Checkbox "Semua"
                            GestureDetector(
                              onTap: () => toggleSelectAll(cart),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: selectAll 
                                      ? const Color(0xFF00AA13) 
                                      : Colors.white,
                                  border: Border.all(
                                    color: selectAll 
                                        ? const Color(0xFF00AA13) 
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: selectAll
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Semua',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total (${getSelectedCount()} item)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  FormatHelper.formatCurrency(calculateSelectedTotal(cart)),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Buy button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: selectedItems.isEmpty 
                                ? null 
                                : () {
                                    print('🛒 Tombol Beli diklik!'); // Debug
                                    print('📦 Item terpilih: ${selectedItems.length}');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CheckoutScreen(),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedItems.isEmpty 
                                  ? Colors.grey[300] 
                                  : const Color(0xFF00AA13),
                              foregroundColor: selectedItems.isEmpty 
                                  ? Colors.grey[500] 
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Beli',
                              style: TextStyle(
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
              ],
            ),
    );
  }
}