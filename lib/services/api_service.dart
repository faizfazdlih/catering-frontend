// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan IP komputer Anda jika test di device fisik
  // Cara cek IP: buka CMD ketik ipconfig (Windows) atau ifconfig (Mac/Linux)
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String noTelepon,
    required String alamat,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'no_telepon': noTelepon,
        'alamat': alamat,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Menu
  static Future<List<dynamic>> getMenu() async {
    final response = await http.get(Uri.parse('$baseUrl/menu'));
    final data = jsonDecode(response.body);
    return data['menu'];
  }

  // Ongkir
  static Future<Map<String, dynamic>> calculateOngkir(double jarakKm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ongkir/calculate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'jarak_km': jarakKm}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOngkirInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/ongkir/info'));
    return jsonDecode(response.body);
  }

  // Pesanan
  static Future<Map<String, dynamic>> createPesanan({
    required int userId,
    required String tanggalPesan,
    required String waktuPengiriman,
    required String alamatPengiriman,
    required double jarakKm,
    required double ongkir,
    required List<Map<String, dynamic>> items,
    String? catatan,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pesanan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'tanggal_pesan': tanggalPesan,
        'waktu_pengiriman': waktuPengiriman,
        'alamat_pengiriman': alamatPengiriman,
        'jarak_km': jarakKm,
        'ongkir': ongkir,
        'items': items,
        'catatan': catatan,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getUserPesanan(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pesanan/user/$userId'),
    );
    final data = jsonDecode(response.body);
    return data['pesanan'];
  }

  static Future<Map<String, dynamic>> getPesananDetail(int pesananId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pesanan/$pesananId'),
    );
    return jsonDecode(response.body);
  }
}