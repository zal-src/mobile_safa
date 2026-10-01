import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ContractFormStyles {
  static InputDecoration fieldDecoration(String hint, {String? label}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff9aa2ad), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xff354052), fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffaeb6c2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffaeb6c2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  static Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xff233044),
      ),
    );
  }

  static Widget buildDateRuleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffcde9df)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'เงื่อนไขวันที่: วันให้กู้ถูกกำหนดเป็นวันนี้เท่านั้นและแก้ไขไม่ได้ ส่วนวันคืนเงินเลือกได้ตั้งแต่วันนี้เป็นต้นไป และไม่สามารถเลือกวันที่ย้อนหลังได้',
              style: TextStyle(
                color: Color(0xff176b5b),
                height: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
