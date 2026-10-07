import 'contract_date_utils.dart';

/// Validator ฟังก์ชันสำหรับฟอร์มสร้างสัญญา
class ContractValidators {
  /// validate อีเมลคู่สัญญา
  /// - [counterpartyText] คือ 'ผู้กู้' หรือ 'ผู้ให้กู้' (ใช้ใน error message)
  /// - [currentUserEmail] คือ email ของผู้ใช้ที่ล็อกอินอยู่ (ห้ามสร้างสัญญากับตัวเอง)
  static String? validateEmail(
    String? value, {
    required String counterpartyText,
    required String currentUserEmail,
  }) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'กรุณาระบุอีเมล$counterpartyText';

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    if (currentUserEmail.trim().toLowerCase() == email.toLowerCase()) {
      return 'ไม่สามารถสร้างสัญญากับตัวเองได้';
    }

    return null;
  }

  /// Optional phone number: when provided, it must contain exactly 10 digits.
  static String? validateOptionalPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty || RegExp(r'^\d{10}$').hasMatch(phone)) return null;
    return 'กรุณากรอกข้อมูลให้ถูกต้อง';
  }

  /// Optional Thai national ID: when provided, it must contain exactly 13 digits.
  static String? validateOptionalIdCard(String? value) {
    final idCard = value?.trim() ?? '';
    if (idCard.isEmpty || RegExp(r'^\d{13}$').hasMatch(idCard)) return null;
    return 'กรุณากรอกข้อมูลให้ถูกต้อง';
  }

  /// validate จำนวนเงิน
  static String? validateAmount(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';

    if (text.isEmpty) return 'กรุณาระบุจำนวนเงิน';

    final amount = double.tryParse(text);
    if (amount == null) return 'กรุณาระบุจำนวนเงินเป็นตัวเลข';
    if (amount < 2000) return 'จำนวนเงินต้องไม่ต่ำกว่า 2,000 บาท';

    return null;
  }

  /// validate วันคืนเงิน
  /// - ต้องไม่เป็นวันที่ย้อนหลัง
  /// - ต้องไม่ก่อนวันให้กู้ ([loanDateText])
  static String? validateReturnDate(
    String? value, {
    required String loanDateText,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณาเลือกวันคืนเงิน';

    final selected = ContractDateUtils.parseDate(text);
    if (selected == null) return 'รูปแบบวันที่ไม่ถูกต้อง';

    final today = ContractDateUtils.today();
    if (selected.isBefore(today)) {
      return 'วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง';
    }

    final loanDate = ContractDateUtils.parseDate(loanDateText);
    if (loanDate != null && selected.isBefore(loanDate)) {
      return 'วันคืนเงินต้องไม่ก่อนวันให้กู้';
    }

    return null;
  }
}
