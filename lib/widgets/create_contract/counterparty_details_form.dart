import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'contract_form_styles.dart';

class CounterpartyDetailsForm extends StatelessWidget {
  final bool isLender;
  final bool isSaving;
  final String counterpartyText;
  final String counterpartyLabel;
  final String counterpartyHint;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController idCardController;
  final TextEditingController addressController;
  final TextEditingController emailController;
  final Key? counterpartyKey;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePhone;
  final String? Function(String?) validateIdCard;

  const CounterpartyDetailsForm({
    super.key,
    required this.isLender,
    required this.isSaving,
    required this.counterpartyText,
    required this.counterpartyLabel,
    required this.counterpartyHint,
    required this.nameController,
    required this.phoneController,
    required this.idCardController,
    required this.addressController,
    required this.emailController,
    this.counterpartyKey,
    required this.validateEmail,
    required this.validatePhone,
    required this.validateIdCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffe2e7eb)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 18, color: const Color(0xfff3a43b)),
              const SizedBox(width: 7),
              Text(
                'ข้อมูลคู่สัญญา - $counterpartyText',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextFormField(
            controller: nameController,
            enabled: !isSaving,
            textInputAction: TextInputAction.next,
            decoration: ContractFormStyles.fieldDecoration(
              'ระบุชื่อ-นามสกุล',
              label: 'ชื่อ-นามสกุล',
            ),
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: phoneController,
            enabled: !isSaving,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: validatePhone,
            decoration: ContractFormStyles.fieldDecoration(
              'กรอก 10 หลัก เช่น 0812345678',
              label: 'เบอร์โทรศัพท์',
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: idCardController,
            enabled: !isSaving,
            keyboardType: TextInputType.number,
            maxLength: 13,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            validator: validateIdCard,
            decoration: ContractFormStyles.fieldDecoration(
              'กรอก 13 หลัก',
              label: isLender ? 'เลขบัตรประชาชน (ผู้กู้)' : 'เลขบัตรประชาชน',
            ).copyWith(counterText: ''),
          ),
          if (isLender) ...[
            const SizedBox(height: 11),
            TextFormField(
              controller: addressController,
              enabled: !isSaving,
              maxLines: 2,
              decoration: ContractFormStyles.fieldDecoration(
                'บ้านเลขที่, หมู่, ซอย, ถนน, ตำบล/แขวง, อำเภอ/เขต, จังหวัด, รหัสไปรษณีย์',
                label: 'ที่อยู่ตามทะเบียนบ้าน',
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'กรอกที่อยู่ที่ต้องการแสดงในสัญญา',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            TextFormField(
              enabled: !isSaving,
              maxLines: 2,
              decoration: ContractFormStyles.fieldDecoration(
                'ระบุที่อยู่ที่ต้องการแสดงในสัญญา',
                label: 'ที่อยู่สำหรับสัญญา',
              ),
            ),
          ] else ...[
            const SizedBox(height: 11),
            TextFormField(
              controller: addressController,
              enabled: !isSaving,
              maxLines: 2,
              decoration: ContractFormStyles.fieldDecoration(
                'บ้านเลขที่, หมู่, ซอย, ถนน, ตำบล/แขวง, อำเภอ/เขต, จังหวัด, รหัสไปรษณีย์',
                label: 'ที่อยู่ (ผู้ให้กู้)',
              ),
            ),
          ],
          const SizedBox(height: 11),
          TextFormField(
            key: counterpartyKey,
            controller: emailController,
            enabled: !isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: ContractFormStyles.fieldDecoration(
              counterpartyHint,
              label: '$counterpartyLabel ',
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 15,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'หากคู่สัญญายังไม่ได้สมัครในระบบ ระบบจะสร้างบัญชีชั่วคราวให้อัตโนมัติ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
