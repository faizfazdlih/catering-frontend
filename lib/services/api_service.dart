// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.X:3000/api'; // Device Fisik
  
  static void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Terjadi kesalahan');
    }
  }

  // ==================== CLIENT AUTH ====================
  
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String noTelepon,
    required String alamat,
  }) async {
    try {
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
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // Unified Login (akan detect role dari backend)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'role': data['role'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==================== ADMIN AUTH (DEPRECATED - use unified login) ====================
  
  // Keep for backward compatibility
  static Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    // Redirect to unified login with email format
    return login(email: username, password: password);
  }

  // ==================== ADMIN USER MANAGEMENT ====================
  
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/admin/users'));
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['users'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat users: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getPendingUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/admin/pending-users'));
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['users'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat pending users: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/admin/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ADMIN: Update User Role (NEW)
  static Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/admin/users/$userId/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== MENU ====================
  
  static Future<List<dynamic>> getMenu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu'));
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['menu'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat menu: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getMenuById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu/$id'));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memuat detail menu: ${e.toString()}');
    }
  }

  // ADMIN: Add Menu
  static Future<Map<String, dynamic>> addMenu({
    required String namaMenu,
    required String deskripsi,
    required double harga,
    required String kategori,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/menu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_menu': namaMenu,
          'deskripsi': deskripsi,
          'harga': harga,
          'kategori': kategori,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ADMIN: Update Menu
  static Future<Map<String, dynamic>> updateMenu({
    required int id,
    required String namaMenu,
    required String deskripsi,
    required double harga,
    required String kategori,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/menu/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_menu': namaMenu,
          'deskripsi': deskripsi,
          'harga': harga,
          'kategori': kategori,
          'status': status,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ADMIN: Delete Menu
  static Future<Map<String, dynamic>> deleteMenu(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/menu/$id'));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== ONGKIR ====================
  
  static Future<Map<String, dynamic>> calculateOngkir(double jarakKm) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ongkir/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'jarak_km': jarakKm}),
      );
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal menghitung ongkir: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getOngkirInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ongkir/info'));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memuat info ongkir: ${e.toString()}');
    }
  }

  // ==================== PESANAN ====================
  
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
    try {
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
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat pesanan: ${e.toString()}'};
    }
  }

  static Future<List<dynamic>> getUserPesanan(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pesanan/user/$userId'),
      );
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['pesanan'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  // ADMIN: Get All Pesanan
  static Future<List<dynamic>> getAllPesanan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pesanan'));
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['pesanan'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getPesananDetail(int pesananId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pesanan/$pesananId'),
      );
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: ${e.toString()}');
    }
  }

  // ADMIN: Update Pesanan Status
  static Future<Map<String, dynamic>> updatePesananStatus(int pesananId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/pesanan/$pesananId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ADMIN: Get Statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pesanan/admin/statistics'),
      );
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memuat statistik: ${e.toString()}');
    }
  }
}