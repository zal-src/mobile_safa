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

  Future<User?> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    String? password,
    String? phone,
    String? idCard,
    String? houseNumber,
    String? village,
    String? road,
    String? subdistrict,
    String? district,
    String? province,
    String? postalCode,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = await _database.getUserByEmail(normalizedEmail);

    if (existingUser != null &&
        (existingUser['user_id'] as int?) != null &&
        existingUser['user_id'] != userId) {
      throw Exception('อีเมลนี้ถูกใช้งานแล้ว');
    }

    final updates = <String, dynamic>{
      'full_name': fullName.trim(),
      'email': normalizedEmail,
      'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
      'id_card': idCard == null || idCard.trim().isEmpty ? null : idCard.trim(),
    };

    if (password != null && password.trim().isNotEmpty) {
      updates['password'] = password;
    }

    await _database.updateUser(userId, updates);

    final addressParts = <String>[];
    if (houseNumber != null && houseNumber.trim().isNotEmpty) {
      addressParts.add('บ้านเลขที่ ${houseNumber.trim()}');
    }
    if (village != null && village.trim().isNotEmpty) {
      addressParts.add('หมู่ ${village.trim()}');
    }
    if (road != null && road.trim().isNotEmpty) {
      addressParts.add('ถนน ${road.trim()}');
    }

    final addressValues = <String, dynamic>{
      'user_id': userId,
      'address_type': 'registered',
      'address': addressParts.join(' '),
      'province': province == null || province.trim().isEmpty ? null : province.trim(),
      'district': district == null || district.trim().isEmpty ? null : district.trim(),
      'subdistrict': subdistrict == null || subdistrict.trim().isEmpty ? null : subdistrict.trim(),
      'postal_code': postalCode == null || postalCode.trim().isEmpty ? null : postalCode.trim(),
    };

    final existingAddress = await _database.getUserAddress(userId);
    if (existingAddress != null ||
        addressValues['address'] != '' ||
        addressValues['province'] != null ||
        addressValues['district'] != null ||
        addressValues['subdistrict'] != null ||
        addressValues['postal_code'] != null) {
      if (existingAddress != null) {
        await _database.updateUserAddress(userId, addressValues);
      } else {
        await _database.insertAddress(addressValues);
      }
    }

    final refreshed = await _database.getUserById(userId);
    if (refreshed == null) {
      return null;
    }

    return User.fromMap(refreshed);
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