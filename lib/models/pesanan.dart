// models/pesanan.dart
class Pesanan {
  final int id;
  final int userId;
  final String tanggalPesan;
  final String? waktuPengiriman;
  final String alamatPengiriman;
  final double? jarakKm;
  final double? ongkir;
  final double totalHarga;
  final String status;
  final String? catatan;
  final String createdAt;
  final int? jumlahItem;

  Pesanan({
    required this.id,
    required this.userId,
    required this.tanggalPesan,
    this.waktuPengiriman,
    required this.alamatPengiriman,
    this.jarakKm,
    this.ongkir,
    required this.totalHarga,
    required this.status,
    this.catatan,
    required this.createdAt,
    this.jumlahItem,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      id: json['id'],
      userId: json['user_id'],
      tanggalPesan: json['tanggal_pesan'],
      waktuPengiriman: json['waktu_pengiriman'],
      alamatPengiriman: json['alamat_pengiriman'],
      jarakKm: json['jarak_km'] != null ? double.parse(json['jarak_km'].toString()) : null,
      ongkir: json['ongkir'] != null ? double.parse(json['ongkir'].toString()) : null,
      totalHarga: double.parse(json['total_harga'].toString()),
      status: json['status'],
      catatan: json['catatan'],
      createdAt: json['created_at'],
      jumlahItem: json['jumlah_item'],
    );
  }
}

class PesananDetail {
  final int id;
  final int pesananId;
  final int menuId;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String? namaMenu;
  final String? kategori;

  PesananDetail({
    required this.id,
    required this.pesananId,
    required this.menuId,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.namaMenu,
    this.kategori,
  });

  factory PesananDetail.fromJson(Map<String, dynamic> json) {
    return PesananDetail(
      id: json['id'],
      pesananId: json['pesanan_id'],
      menuId: json['menu_id'],
      jumlah: json['jumlah'],
      hargaSatuan: double.parse(json['harga_satuan'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      namaMenu: json['nama_menu'],
      kategori: json['kategori'],
    );
  }
}