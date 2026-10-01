import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../widgets/register/register_ui_components.dart';
import '../widgets/register/account_info_form.dart';
import '../widgets/register/address_form.dart';
import '../widgets/register/register_ai_assistant.dart';

// =============================================================================
// RegisterPage
// - หน้าสมัครสมาชิก แบ่งเป็น 2 หมวด:
//   01 - ข้อมูลบัญชี  → widgets/register/account_info_form.dart
//   02 - ที่อยู่        → widgets/register/address_form.dart
//
// Widget ย่อยที่เกี่ยวข้อง (ดูใน lib/widgets/register/):
//   - account_info_form.dart       → ฟอร์มบัญชี (ชื่อ/อีเมล/รหัสผ่าน/เบอร์/บัตร)
//   - address_form.dart            → ฟอร์มที่อยู่ (บ้านเลขที่ ถึง ไปรษณีย์)
//   - register_ai_assistant.dart   → กล่อง "Safa ช่วยตรวจข้อมูล"
//   - register_ui_components.dart  → CategoryHeader, FieldLabel, PasswordRuleRow
//   - register_validators.dart     → validate phone/idCard/postalCode/password
// =============================================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // ── Controllers: ข้อมูลบัญชี ──────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();

  // ── Controllers: ที่อยู่ ───────────────────────────────────────────────────
  final _houseNumberController = TextEditingController();
  final _villageController = TextEditingController();
  final _roadController = TextEditingController();
  final _subdistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showAiInsight = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _houseNumberController.dispose();
    _villageController.dispose();
    _roadController.dispose();
    _subdistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        idCard: _idCardController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        village: _villageController.text.trim().isEmpty
            ? null
            : _villageController.text.trim(),
        road: _roadController.text.trim().isEmpty
            ? null
            : _roadController.text.trim(),
        subdistrict: _subdistrictController.text.trim(),
        district: _districtController.text.trim(),
        province: _provinceController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกสำเร็จ: ${user?.fullName}')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.buildSafaAppBar(context, title: 'สมัครสมาชิก'),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _register,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(_isLoading ? 'กำลังสร้างบัญชี...' : 'บันทึกข้อมูลพื้นฐาน'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: Responsive.formMaxWidth(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 8),
                  const Text(
                    'สร้างบัญชีใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'กรอกข้อมูลเพื่อเริ่มใช้งาน Safa',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),

                  // ── หมวด 01: ข้อมูลบัญชี ────────────────────────────────
                  const RegisterCategoryHeader(
                    category: 'หมวด 01',
                    title: 'ข้อมูลบัญชี',
                    count: '1/2',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'กรอกข้อมูลพื้นฐานเพื่อสร้างบัญชีและใช้จัดทำสัญญาได้อย่างถูกต้อง',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),

                  AccountInfoForm(
                    isLoading: _isLoading,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    phoneController: _phoneController,
                    idCardController: _idCardController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirmPassword: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── หมวด 02: ที่อยู่ ─────────────────────────────────────
                  const RegisterCategoryHeader(
                    category: 'หมวด 02',
                    title: 'ที่อยู่สำหรับสัญญา',
                    count: '2/2',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ที่อยู่นี้จะถูกบันทึกไว้ในบัญชี และจะแสดงในเอกสารสัญญาเฉพาะส่วนของผู้กู้',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  AddressForm(
                    isLoading: _isLoading,
                    houseNumberController: _houseNumberController,
                    villageController: _villageController,
                    roadController: _roadController,
                    subdistrictController: _subdistrictController,
                    districtController: _districtController,
                    provinceController: _provinceController,
                    postalCodeController: _postalCodeController,
                  ),
                  const SizedBox(height: 24),

                  // ── Safa AI Assistant ─────────────────────────────────────
                  RegisterAiAssistant(
                    isLoading: _isLoading,
                    showInsight: _showAiInsight,
                    onToggleInsight: () =>
                        setState(() => _showAiInsight = !_showAiInsight),
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    idCard: _idCardController.text,
                    password: _passwordController.text,
                    houseNumber: _houseNumberController.text,
                    province: _provinceController.text,
                    postalCode: _postalCodeController.text,
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
