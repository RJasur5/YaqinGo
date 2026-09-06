import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Parses a date string from the backend and ensures it's treated as UTC 
  /// before converting to the user's local timezone.
  static DateTime parseUtc(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    
    try {
      // If the string doesn't have a timezone indicator (Z or +/-), append Z
      // to force parse it as UTC.
      String normalized = dateStr.trim();
      if (!normalized.contains('Z') && !normalized.contains('+') && !normalized.contains('-')) {
        // If there's a space instead of T, replace it for standard ISO compatibility
        normalized = normalized.replaceAll(' ', 'T');
        normalized = '${normalized}Z';
      }
      
      return DateTime.parse(normalized).toLocal();
    } catch (e) {
      print('DateTimeUtils Error parsing "$dateStr": $e');
      return DateTime.now();
    }
  }

  /// Formats a date for display: "dd.MM HH:mm"
  static String formatFull(DateTime dateTime) {
    return DateFormat('dd.MM HH:mm').format(dateTime);
  }

  /// Formats a time for display: "HH:mm"
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Formats a date for reviews: "dd.MM.yyyy"
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  /// Formats for "Join date": "MMMM yyyy"
  static String formatMonthYear(DateTime dateTime, String locale) {
    return DateFormat('MMMM yyyy', locale).format(dateTime);
  }
}
