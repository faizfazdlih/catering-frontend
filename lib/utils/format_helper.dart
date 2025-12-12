// lib/utils/format_helper.dart
import 'package:intl/intl.dart';

class FormatHelper {
  // Format currency: Rp 25.000
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'Rp ${formatter.format(amount)}';
  }
  
  // Format date: 25/12/2024
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Format date with month name: 25 Desember 2024
  static String formatDateWithMonth(DateTime date) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
  
  // Format date short: 25 Des 2024
  static String formatDateShort(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
  
  // Format time: 14:30
  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      return '${parts[0]}:${parts[1]}';
    } catch (e) {
      return time;
    }
  }
  
  // Format datetime for API: 2024-12-25
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Format time for API: 14:30:00
  static String formatTimeForApi(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}