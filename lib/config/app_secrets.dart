import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ตัวกลางสำหรับเข้าถึงค่า secret ที่โหลดมาจาก .env หรือใช้ Default Key
abstract final class AppSecrets {
  /// Default Gemini API Key เพื่อให้เพื่อนที่ Clone โค้ดไปสามารถรันแอปและใช้งาน AI ได้ทันที 100% ฟรี
  /// ไม่ต้องติดตั้ง Ollama หรือ Python ใดๆ ทั้งสิ้น
  static const String _defaultGeminiApiKey =
      'AQ.Ab8RN6KxIwMbEft5VYarv3v6V38PkI4VOsSJxN8qTRoph0T5JA';

  /// ดึง Gemini API Key (ถ้ามีใน .env จะใช้จาก .env ก่อน หากไม่มีจะใช้ Default Key อัตโนมัติ)
  static String get geminiApiKey {
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.trim().isNotEmpty) {
        return envKey.trim();
      }
    } catch (_) {}
    return _defaultGeminiApiKey;
  }
}
