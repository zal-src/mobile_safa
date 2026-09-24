import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? idCard,

    required String houseNumber,
    String? village,
    String? road,
    required String subdistrict,
    required String district,
    required String province,
    required String postalCode,
  }) async {
    // ตรวจสอบอีเมลซ้ำ
    final existingUser =
        await _database.getUserByEmail(
      email,
    );

    int userId;

    if (existingUser != null) {
      final existingPassword =
          (existingUser['password'] as String?)?.trim() ?? '';
      if (existingPassword.isNotEmpty) {
        throw Exception(
          'อีเมลนี้ถูกใช้งานแล้ว',
        );
      }

      // บัญชีชั่วคราวที่สร้างขึ้นจากสัญญา (ยังไม่มีรหัสผ่าน)
      // ให้ทำการอัปเดตข้อมูลบัญชี
      userId = existingUser['user_id'] as int;

      await _database.updateUser(userId, {
        'full_name': fullName,
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone,
        'id_card': idCard,
      });
    } else {
      final user = User(
        fullName: fullName,
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone,
        idCard: idCard,
      );

      userId = await _database.insertUser(
        user.toMap(),
      );
    }

    // ------------------------------------------
    // สร้างข้อความที่อยู่หลัก
    // ------------------------------------------

    final addressParts = <String>[];

    addressParts.add(
      'บ้านเลขที่ $houseNumber',
    );

    if (village != null &&
        village.trim().isNotEmpty) {
      addressParts.add(
        'หมู่ ${village.trim()}',
      );
    }

    if (road != null &&
        road.trim().isNotEmpty) {
      addressParts.add(
        'ถนน ${road.trim()}',
      );
    }

    // ------------------------------------------
    // บันทึกที่อยู่
    // ------------------------------------------

    final existingAddress =
        await _database.getUserAddress(userId);
    final addressData = {
      'user_id': userId,
      'address_type': 'registered',
      'address': addressParts.join(' '),
      'province': province.trim(),
      'district': district.trim(),
      'subdistrict': subdistrict.trim(),
      'postal_code': postalCode.trim(),
    };

    if (existingAddress != null) {
      await _database.updateUserAddress(
        userId,
        addressData,
      );
    } else {
      await _database.insertAddress(
        addressData,
      );
    }

    return User(
      userId: userId,
      fullName: fullName,
      email: email.trim().toLowerCase(),
      password: password,
      phone: phone,
      idCard: idCard,
    );
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final result =
        await _database.loginUser(
      email,
      password,
    );

    if (result == null) {
      return null;
    }

    return User.fromMap(result);
  }
}