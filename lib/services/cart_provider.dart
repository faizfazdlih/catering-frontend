// services/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/menu.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalHarga {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.jumlah);
  }

  void addItem(Menu menu) {
    // Cek apakah menu sudah ada di cart
    final existingIndex = _items.indexWhere((item) => item.menu.id == menu.id);
    
    if (existingIndex >= 0) {
      // Jika sudah ada, tambah jumlahnya
      _items[existingIndex].jumlah++;
    } else {
      // Jika belum ada, tambah item baru
      _items.add(CartItem(menu: menu, jumlah: 1));
    }
    
    notifyListeners();
  }

  void removeItem(int menuId) {
    _items.removeWhere((item) => item.menu.id == menuId);
    notifyListeners();
  }

  void updateQuantity(int menuId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(menuId);
      return;
    }

    final existingIndex = _items.indexWhere((item) => item.menu.id == menuId);
    if (existingIndex >= 0) {
      _items[existingIndex].jumlah = newQuantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(int menuId) {
    return _items.any((item) => item.menu.id == menuId);
  }

  int getQuantity(int menuId) {
    final item = _items.firstWhere(
      (item) => item.menu.id == menuId,
      orElse: () => CartItem(menu: Menu(
        id: 0,
        namaMenu: '',
        harga: 0,
        status: '',
      ), jumlah: 0),
    );
    return item.jumlah;
  }
}