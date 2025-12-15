// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.X:3000/api'; // Device Fisik

  // Helper untuk mendapatkan URL gambar lengkap
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // Jika sudah berupa URL lengkap, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Jika relative path, gabungkan dengan base URL (tanpa /api)
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    return '$baseUrlWithoutApi$relativePath';
  }

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
        body: jsonEncode({'email': email, 'password': password}),
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
      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/pending-users'),
      );
      _handleError(response);
      final data = jsonDecode(response.body);
      return data['users'] ?? [];
    } catch (e) {
      throw Exception('Gagal memuat pending users: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(
    int userId,
    String status,
  ) async {
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
  static Future<Map<String, dynamic>> updateUserRole(
    int userId,
    String role,
  ) async {
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

  // ADMIN: Add Menu (Simple - tanpa image)
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

  // ADMIN: Update Menu (Simple - tanpa image)
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

  // ADMIN: Add Menu dengan Image Upload
  static Future<Map<String, dynamic>> addMenuWithImage({
    required String namaMenu,
    required String deskripsi,
    required double harga,
    required String kategori,
    dynamic imageFile, // XFile from image_picker
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/menu'),
      );

      // Add text fields
      request.fields['nama_menu'] = namaMenu;
      request.fields['deskripsi'] = deskripsi;
      request.fields['harga'] = harga.toString();
      request.fields['kategori'] = kategori;

      // Add image file if exists
      if (imageFile != null) {
        var bytes = await imageFile.readAsBytes();
        
        // Get original filename and extension
        final String originalPath = imageFile.path;
        String extension = '.jpg'; // default
        String mimeType = 'image/jpeg'; // default
        
        // Try to get extension from path
        if (originalPath.contains('.')) {
          final parts = originalPath.split('.');
          final ext = parts.last.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
            extension = '.$ext';
            
            // Set correct MIME type
            if (ext == 'png') {
              mimeType = 'image/png';
            } else if (ext == 'gif') {
              mimeType = 'image/gif';
            } else if (ext == 'webp') {
              mimeType = 'image/webp';
            } else {
              mimeType = 'image/jpeg';
            }
          }
        }
        
        // Generate filename dengan extension yang benar
        final String filename = 'menu_${DateTime.now().millisecondsSinceEpoch}$extension';

        var multipartFile = http.MultipartFile.fromBytes(
          'foto', // Sesuai dengan upload.single('foto') di backend
          bytes,
          filename: filename,
          contentType: http_parser.MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
        
        print('📤 Uploading: $filename (${bytes.length} bytes, $mimeType)');
      }

      print('📍 POST: ${request.url}');
      print('📝 Fields: ${request.fields}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('✅ Status: ${response.statusCode}');
      print('📄 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      // Check if response is HTML error page
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html') ||
          response.body.trim().startsWith('<')) {
        return {
          'success': false, 
          'message': 'Server error (${response.statusCode}): Pastikan backend running dan endpoint /api/menu tersedia'
        };
      }

      var data = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Menu berhasil ditambahkan'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menambahkan menu'};
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack: $stackTrace');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ADMIN: Update Menu dengan Image Upload
  static Future<Map<String, dynamic>> updateMenuWithImage({
    required int id,
    required String namaMenu,
    required String deskripsi,
    required double harga,
    required String kategori,
    required String status,
    dynamic imageFile, // XFile from image_picker
    String? existingImageUrl,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/menu/$id'),
      );

      request.fields['nama_menu'] = namaMenu;
      request.fields['deskripsi'] = deskripsi;
      request.fields['harga'] = harga.toString();
      request.fields['kategori'] = kategori;
      request.fields['status'] = status;
      
      // Keep existing image URL if no new upload
      if (existingImageUrl != null && imageFile == null) {
        request.fields['foto_url'] = existingImageUrl;
      }

      // Add new image if exists
      if (imageFile != null) {
        var bytes = await imageFile.readAsBytes();
        
        // Get original filename and extension
        final String originalPath = imageFile.path;
        String extension = '.jpg'; // default
        String mimeType = 'image/jpeg'; // default
        
        // Try to get extension from path
        if (originalPath.contains('.')) {
          final parts = originalPath.split('.');
          final ext = parts.last.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
            extension = '.$ext';
            
            // Set correct MIME type
            if (ext == 'png') {
              mimeType = 'image/png';
            } else if (ext == 'gif') {
              mimeType = 'image/gif';
            } else if (ext == 'webp') {
              mimeType = 'image/webp';
            } else {
              mimeType = 'image/jpeg';
            }
          }
        }
        
        // Generate filename dengan extension yang benar
        final String filename = 'menu_${DateTime.now().millisecondsSinceEpoch}$extension';

        var multipartFile = http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: filename,
          contentType: http_parser.MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
        
        print('📤 Uploading: $filename (${bytes.length} bytes, $mimeType)');
      }

      print('📍 PUT: ${request.url}');
      print('📝 Fields: ${request.fields}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('✅ Status: ${response.statusCode}');
      print('📄 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      // Check if response is HTML error page
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html') ||
          response.body.trim().startsWith('<')) {
        return {
          'success': false, 
          'message': 'Server error (${response.statusCode}): Pastikan backend running dan endpoint tersedia'
        };
      }

      var data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Menu berhasil diupdate'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mengupdate menu'};
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack: $stackTrace');
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

  // Calculate ongkir either by providing jarakKm OR by providing destination coordinates
  // destination: { 'lat': double, 'lng': double }
  static Future<Map<String, dynamic>> calculateOngkir({
    double? jarakKm,
    Map<String, double>? destination,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (jarakKm != null) payload['jarak_km'] = jarakKm;
      if (destination != null) payload['destination'] = destination;

      final response = await http.post(
        Uri.parse('$baseUrl/ongkir/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
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
      return {
        'success': false,
        'message': 'Gagal membuat pesanan: ${e.toString()}',
      };
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
      final response = await http.get(Uri.parse('$baseUrl/pesanan/$pesananId'));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: ${e.toString()}');
    }
  }

  // ADMIN: Update Pesanan Status
  static Future<Map<String, dynamic>> updatePesananStatus(
    int pesananId,
    String status,
  ) async {
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
