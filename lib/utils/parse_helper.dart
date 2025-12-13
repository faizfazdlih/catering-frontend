// utils/parse_helper.dart
class ParseHelper {
  // Safely parse dynamic value to double
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Safely parse dynamic value to int
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Safely parse dynamic value to String
  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Safely get value from map with type checking
  static T getValue<T>(Map<String, dynamic> map, String key, T defaultValue) {
    if (!map.containsKey(key)) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is T) return value;
    return defaultValue;
  }
}