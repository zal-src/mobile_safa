import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Widget หัวข้อหมวดหมู่ในฟอร์มสมัครสมาชิก (เช่น หมวด 01 - ข้อมูลบัญชี)
class RegisterCategoryHeader extends StatelessWidget {
  final String category;
  final String title;
  final String count;
  final IconData icon;

  const RegisterCategoryHeader({
    super.key,
    required this.category,
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Label บนฟิลด์ในฟอร์มสมัครสมาชิก (bold + hint เบาๆ)
class RegisterFieldLabel extends StatelessWidget {
  final String text;
  final String? hint;

  const RegisterFieldLabel(this.text, {super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: text),
            if (hint != null)
              TextSpan(
                text: ' $hint',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// แถวตรวจสอบเงื่อนไขรหัสผ่าน (✓ สีเขียว / ○ สีเทา)
class PasswordRuleRow extends StatelessWidget {
  final String label;
  final bool valid;

  const PasswordRuleRow(this.label, {super.key, required this.valid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: valid ? AppColors.primary : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: valid ? AppColors.primaryDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// InputDecoration สำหรับ field ในหมวดข้อมูลบัญชี (ใช้กับฟิลด์รหัสผ่าน/ชื่อ/อีเมล)
InputDecoration accountFieldDecoration({
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
