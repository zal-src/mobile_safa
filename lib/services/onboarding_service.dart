import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Service สำหรับจัดการสถานะ onboarding tutorial ของแต่ละหน้า
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  // key สำหรับแต่ละหน้า
  static const String keyHome = 'onboarding_home';
  static const String keyContracts = 'onboarding_contracts';
  static const String keyKnowledge = 'onboarding_knowledge';
  static const String keyCreateContract = 'onboarding_create_contract';

  /// ตรวจสอบว่าหน้านี้เคยแสดง tutorial แล้วหรือยัง
  Future<bool> hasSeenOnboarding(String key) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      return result.isNotEmpty && result.first['value'] == '1';
    } catch (e) {
      debugPrint('OnboardingService.hasSeenOnboarding error: $e');
      // ถ้า table ยังไม่มีให้ return false เพื่อแสดง tutorial
      return false;
    }
  }

  /// บันทึกว่าหน้านี้เคยแสดง tutorial แล้ว
  Future<void> markAsSeen(String key) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      await db.insert(
        'app_settings',
        {'key': key, 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('OnboardingService.markAsSeen error: $e');
    }
  }

  /// รีเซ็ต tutorial ทั้งหมด (ใช้สำหรับ debug หรือตั้งค่า)
  Future<void> resetAll() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('app_settings');
    } catch (e) {
      debugPrint('OnboardingService.resetAll error: $e');
    }
  }
}
