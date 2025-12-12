// models/user.dart
class User {
  final int id;
  final String nama;
  final String email;
  final String? noTelepon;
  final String? alamat;

  User({
    required this.id,
    required this.nama,
    required this.email,
    this.noTelepon,
    this.alamat,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      noTelepon: json['no_telepon'],
      alamat: json['alamat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_telepon': noTelepon,
      'alamat': alamat,
    };
  }
}