import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class LanguageController {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  static const String _settingKey = 'app_language';
  static const Locale thLocale = Locale('th', 'TH');

  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(thLocale);

  Locale get currentLocale => localeNotifier.value;
  bool get isThai => currentLocale.languageCode == 'th';

  /// โหลดภาษาที่บันทึกไว้จากฐานข้อมูล ถ้าไม่มีให้เริ่มต้นด้วยภาษาไทย
  Future<void> init() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [_settingKey],
      );

      if (result.isNotEmpty) {
        final langCode = result.first['value'] as String?;
        if (langCode != 'th') {
          localeNotifier.value = thLocale;
        }
      }
    } catch (e) {
      debugPrint('LanguageController init error: $e');
      localeNotifier.value = thLocale;
    }
  }
}
