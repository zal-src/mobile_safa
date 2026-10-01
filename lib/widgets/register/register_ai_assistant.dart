import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'register_validators.dart';
import 'register_ui_components.dart';

// =============================================================================
// RegisterAiAssistant
// - กล่อง "Safa ช่วยตรวจข้อมูล" ที่แสดงรายการ checklist จากข้อมูลที่กรอก
// =============================================================================

class RegisterAiAssistant extends StatelessWidget {
  final bool isLoading;
  final bool showInsight;
  final VoidCallback onToggleInsight;

  // ข้อมูลสำหรับสร้าง checklist
  final String name;
  final String email;
  final String phone;
  final String idCard;
  final String password;
  final String houseNumber;
  final String province;
  final String postalCode;

  const RegisterAiAssistant({
    super.key,
    required this.isLoading,
    required this.showInsight,
    required this.onToggleInsight,
    required this.name,
    required this.email,
    required this.phone,
    required this.idCard,
    required this.password,
    required this.houseNumber,
    required this.province,
    required this.postalCode,
  });

  @override
  Widget build(BuildContext context) {
    final checks = <String, bool>{
      'ชื่อและอีเมล': name.trim().isNotEmpty && email.trim().contains('@'),
      'เบอร์โทรศัพท์ (10 หลัก)': RegExp(r'^\d{10}$').hasMatch(phone.trim()),
      'เลขบัตรประชาชน (13 หลัก)': RegExp(r'^\d{13}$').hasMatch(idCard.trim()),
      'รหัสผ่านปลอดภัย': RegisterValidators.validatePassword(password) == null,
      'ที่อยู่สำหรับสัญญา':
          houseNumber.trim().isNotEmpty &&
          province.trim().isNotEmpty &&
          RegExp(r'^\d{5}$').hasMatch(postalCode.trim()),
    };
    final completed = checks.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0a087d66),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Safa ช่วยตรวจข้อมูล',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed/${checks.length}',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ผู้ช่วยจะแนะนำเฉพาะจากข้อมูลที่คุณกรอก ไม่ส่งข้อมูลไปวิเคราะห์ภายนอก',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          if (showInsight) ...[
            const SizedBox(height: 12),
            ...checks.entries.map(
              (entry) => PasswordRuleRow(entry.key, valid: entry.value),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onToggleInsight,
              icon: Icon(
                showInsight ? Icons.visibility_off_outlined : Icons.auto_awesome,
              ),
              label: Text(showInsight ? 'ซ่อนคำแนะนำ' : 'ตรวจข้อมูลกับ Safa'),
            ),
          ),
        ],
      ),
    );
  }
}
