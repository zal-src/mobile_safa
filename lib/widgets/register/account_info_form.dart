import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_ui_components.dart';
import 'register_validators.dart';

// =============================================================================
// AccountInfoForm
// - ฟอร์มข้อมูลบัญชี (หมวด 01): ชื่อ, อีเมล, รหัสผ่าน, เบอร์, เลขบัตร
// =============================================================================

class AccountInfoForm extends StatelessWidget {
  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final TextEditingController idCardController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const AccountInfoForm({
    super.key,
    required this.isLoading,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.idCardController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final pw = passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ชื่อ-นามสกุล
        RegisterFieldLabel('ชื่อ-นามสกุล'),
        TextFormField(
          controller: nameController,
          enabled: !isLoading,
          decoration: accountFieldDecoration(hint: 'ชื่อ-นามสกุล'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกชื่อ-นามสกุล';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // อีเมล
        RegisterFieldLabel('อีเมล'),
        TextFormField(
          controller: emailController,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: accountFieldDecoration(hint: 'example@email.com'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'กรุณากรอกอีเมล';
            if (!value.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // รหัสผ่าน
        RegisterFieldLabel('รหัสผ่าน'),
        TextFormField(
          controller: passwordController,
          enabled: !isLoading,
          obscureText: obscurePassword,
          decoration: accountFieldDecoration(
            hint: 'รหัสผ่าน',
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
              onPressed: onTogglePassword,
              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: RegisterValidators.validatePassword,
        ),
        const SizedBox(height: 10),

        // Password checklist
        PasswordRuleRow('อย่างน้อย 8 ตัวอักษร', valid: RegisterValidators.hasMinLength(pw)),
        PasswordRuleRow('ตัวพิมพ์เล็ก (a-z)', valid: RegisterValidators.hasLowercase(pw)),
        PasswordRuleRow('ตัวพิมพ์ใหญ่ (A-Z)', valid: RegisterValidators.hasUppercase(pw)),
        PasswordRuleRow('ตัวเลข (0-9)', valid: RegisterValidators.hasDigit(pw)),
        PasswordRuleRow('อักขระพิเศษ (!@#...)', valid: RegisterValidators.hasSpecialChar(pw)),
        const SizedBox(height: 13),

        // ยืนยันรหัสผ่าน
        RegisterFieldLabel('ยืนยันรหัสผ่าน'),
        TextFormField(
          controller: confirmPasswordController,
          enabled: !isLoading,
          obscureText: obscureConfirmPassword,
          decoration: accountFieldDecoration(
            hint: 'ยืนยันรหัสผ่าน',
            suffixIcon: IconButton(
              tooltip: obscureConfirmPassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (value) => RegisterValidators.validateConfirmPassword(
            value,
            passwordController.text,
          ),
        ),
        const SizedBox(height: 24),

        // ข้อมูลส่วนตัว
        RegisterFieldLabel('ข้อมูลส่วนตัว'),
        const SizedBox(height: 8),

        // เบอร์โทรศัพท์
        TextFormField(
          controller: phoneController,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'เบอร์โทรศัพท์',
            hintText: 'กรอก 10 หลัก (เช่น 0812345678)',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: RegisterValidators.validatePhone,
        ),
        const SizedBox(height: 16),

        // เลขบัตรประชาชน
        TextFormField(
          controller: idCardController,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          maxLength: 13,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: const InputDecoration(
            labelText: 'เลขบัตรประชาชน',
            hintText: 'กรอก 13 หลัก',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: RegisterValidators.validateIdCard,
        ),
      ],
    );
  }
}
