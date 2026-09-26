import 'package:flutter_test/flutter_test.dart';
import 'package:safa_qard/database/database_helper.dart';
import 'package:safa_qard/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('repayments');
    await db.delete('signatures');
    await db.delete('loan_contracts');
    await db.delete('addresses');
    await db.delete('users');
  });

  test('updates the account profile and allows login with the new credentials', () async {
    final authService = AuthService();

    final createdUser = await authService.register(
      fullName: 'สมชาย ใจดี',
      email: 'somchai@example.com',
      password: 'OldPass@123',
      phone: '0812345678',
      idCard: '1234567890123',
      houseNumber: '123',
      subdistrict: 'บางเขน',
      district: 'หลักสี่',
      province: 'กรุงเทพฯ',
      postalCode: '10210',
    );

    expect(createdUser, isNotNull);

    final updatedUser = await authService.updateProfile(
      userId: createdUser!.userId!,
      fullName: 'สมชาย ใจดีใหม่',
      email: 'newmail@example.com',
      password: 'NewPass@456',
      phone: '0998765432',
      idCard: '9876543210987',
      houseNumber: '456',
      village: '12',
      road: 'สุขุมวิท',
      subdistrict: 'ลาดพร้าว',
      district: 'ลาดพร้าว',
      province: 'กรุงเทพมหานคร',
      postalCode: '10230',
    );

    expect(updatedUser, isNotNull);
    expect(updatedUser!.fullName, 'สมชาย ใจดีใหม่');
    expect(updatedUser.email, 'newmail@example.com');
    expect(updatedUser.phone, '0998765432');
    expect(updatedUser.idCard, '9876543210987');

    final savedAddress = await DatabaseHelper.instance.getUserAddress(createdUser.userId!);
    expect(savedAddress, isNotNull);
    expect(savedAddress!['address'], 'บ้านเลขที่ 456 หมู่ 12 ถนน สุขุมวิท');
    expect(savedAddress['subdistrict'], 'ลาดพร้าว');
    expect(savedAddress['district'], 'ลาดพร้าว');
    expect(savedAddress['province'], 'กรุงเทพมหานคร');
    expect(savedAddress['postal_code'], '10230');

    final loggedInUser = await authService.login(
      email: 'newmail@example.com',
      password: 'NewPass@456',
    );

    expect(loggedInUser, isNotNull);
    expect(loggedInUser!.fullName, 'สมชาย ใจดีใหม่');
  });
}
