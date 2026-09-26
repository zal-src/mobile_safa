import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import 'create_contract_page.dart';

/// หน้านี้ใช้เลือกบทบาทก่อนสร้างสัญญา
///
/// ทั้งผู้ให้กู้และผู้กู้จะไปยัง CreateContractPage หน้าเดียวกัน
/// แต่ CreateContractPage จะปรับข้อความ/ข้อมูลคู่สัญญาตาม role ที่เลือก
/// ทำให้ไม่ต้องมีหน้าฟอร์ม 2 ชุดที่ทำงานซ้ำกัน
class ContractRolePage extends StatelessWidget {
  final User user;

  const ContractRolePage({super.key, required this.user});

  Future<void> _selectRole(BuildContext context, String role) async {
    // กันค่า role ที่ไม่ถูกต้องไม่ให้หลุดเข้าไปในหน้าสร้างสัญญา
    if (role != 'lender' && role != 'borrower') {
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateContractPage(user: user, role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างสัญญา')),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: Responsive.formMaxWidth(context),
          child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context), 24,
            Responsive.horizontalPadding(context), 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'เลือกบทบาทของคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff101828),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณมีบทบาทอะไรในสัญญานี้?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              _RoleButton(
                icon: Icons.account_balance_wallet_outlined,
                title: 'ฉันเป็นผู้ให้กู้',
                subtitle: 'ผู้ให้กู้',
                description: 'สร้างสัญญาในฐานะผู้ให้กู้ และระบุอีเมลของผู้กู้',
                color: AppColors.primary,
                onTap: () => _selectRole(context, 'lender'),
              ),
              const SizedBox(height: 14),
              _RoleButton(
                icon: Icons.person_outline,
                title: 'ฉันเป็นผู้กู้',
                subtitle: 'ผู้กู้',
                description: 'สร้างสัญญาในฐานะผู้กู้ และระบุอีเมลของผู้ให้กู้',
                color: AppColors.accent,
                onTap: () => _selectRole(context, 'borrower'),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ข้อมูลของบัญชีที่เข้าสู่ระบบจะถูกใช้เป็นข้อมูลของคุณอัตโนมัติ โดยไม่ต้องกรอกข้อมูลส่วนตัวของคุณซ้ำ',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff101828),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
