import 'package:intl/intl.dart';

/// ฟังก์ชัน utility เกี่ยวกับวันที่ สำหรับหน้าสร้างสัญญา
class ContractDateUtils {
  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');

  /// วันนี้ (ตัดเวลาออก)
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// ตัดเวลาออก เหลือแค่วันที่
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// เปรียบเทียบวันที่ (ไม่สนเวลา)
  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// แปลง DateTime → String รูปแบบ yyyy-MM-dd
  static String formatDate(DateTime date) {
    final value = dateOnly(date);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  /// แปลง String (yyyy-MM-dd) → DateTime? (null ถ้า parse ไม่ได้)
  static DateTime? parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return dateOnly(DateTime.parse(text));
    } catch (_) {
      return null;
    }
  }

  /// แปลง String (yyyy-MM-dd) → String รูปแบบ dd/MM/yyyy สำหรับแสดงผล
  static String displayDate(String value) {
    final date = parseDate(value);
    return date == null ? '' : _displayDateFormat.format(date);
  }
}
