// models/menu.dart
class Menu {
  final int id;
  final String namaMenu;
  final String? deskripsi;
  final double harga;
  final String? kategori;
  final String? fotoUrl;
  final String status;

  Menu({
    required this.id,
    required this.namaMenu,
    this.deskripsi,
    required this.harga,
    this.kategori,
    this.fotoUrl,
    required this.status,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      namaMenu: json['nama_menu'],
      deskripsi: json['deskripsi'],
      harga: double.parse(json['harga'].toString()),
      kategori: json['kategori'],
      fotoUrl: json['foto_url'],
      status: json['status'] ?? 'tersedia',
    );
  }
}

class CartItem {
  final Menu menu;
  int jumlah;

  CartItem({required this.menu, this.jumlah = 1});

  double get subtotal => menu.harga * jumlah;
}