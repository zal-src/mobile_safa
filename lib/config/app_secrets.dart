import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ตัวกลางสำหรับเข้าถึงค่า Secret ที่โหลดมาจาก .env หรือ Environment Variable
/// ⚠️ ห้าม Hardcode API Key หรือข้อมูลลับใดๆ ลงในไฟล์นี้เด็ดขาดตามหลัก Security Best Practice
abstract final class AppSecrets {
  /// ดึง Gemini API Key จาก .env หรือ --dart-define
  static String get geminiApiKey {
    try {
      // 1. อ่านจากไฟล์ .env ในเครื่อง
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.trim().isNotEmpty) {
        return envKey.trim();
      }
    } catch (_) {}

    // 2. อ่านจาก --dart-define (กรณีส่งค่าผ่าน CLI: flutter run --dart-define=GEMINI_API_KEY=xxx)
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }

    return '';
  }

  /// ตรวจสอบว่ามีการตั้งค่า API Key ในระบบแล้วหรือไม่
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
