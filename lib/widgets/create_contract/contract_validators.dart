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

  /// validate จำนวนเงิน
  static String? validateAmount(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';

    if (text.isEmpty) return 'กรุณาระบุจำนวนเงิน';

    final amount = double.tryParse(text);
    if (amount == null) return 'กรุณาระบุจำนวนเงินเป็นตัวเลข';
    if (amount <= 0) return 'จำนวนเงินต้องมากกว่า 0';

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
