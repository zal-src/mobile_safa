/// Validator ฟังก์ชันสำหรับฟอร์มสมัครสมาชิก
class RegisterValidators {
  /// validate เบอร์โทรศัพท์ (10 หลัก)
  static String? validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
    if (!RegExp(r'^\d{10}$').hasMatch(text)) return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
    return null;
  }

  /// validate เลขบัตรประชาชน (13 หลัก)
  static String? validateIdCard(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอกเลขบัตรประชาชน';
    if (!RegExp(r'^\d{13}$').hasMatch(text)) return 'เลขบัตรประชาชนต้องมี 13 หลัก';
    return null;
  }

  /// validate รหัสไปรษณีย์ (5 หลัก)
  static String? validatePostalCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอกรหัสไปรษณีย์';
    if (!RegExp(r'^\d{5}$').hasMatch(text)) return 'รหัสไปรษณีย์ต้องมี 5 หลัก';
    return null;
  }

  /// validate ยืนยันรหัสผ่าน
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (value != password) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  /// validate รหัสผ่าน (ต้องมี ตัวพิมพ์เล็ก/ใหญ่/เลข/อักขระพิเศษ ≥ 8 ตัว)
  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (password.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'รหัสผ่านต้องมีตัวพิมพ์เล็ก';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'รหัสผ่านต้องมีตัวพิมพ์ใหญ่';
    if (!RegExp(r'\d').hasMatch(password)) return 'รหัสผ่านต้องมีตัวเลข';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) return 'รหัสผ่านต้องมีอักขระพิเศษ';
    return null;
  }

  /// ตรวจว่า password ผ่านเกณฑ์นี้ไหม (ใช้แสดง checklist UI)
  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasDigit(String password) => RegExp(r'\d').hasMatch(password);
  static bool hasSpecialChar(String password) => RegExp(r'[^A-Za-z0-9]').hasMatch(password);
}
