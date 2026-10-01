import 'package:flutter/material.dart';
import 'contract_form_styles.dart';

class ContractDetailsForm extends StatelessWidget {
  final bool isSaving;
  final TextEditingController amountController;
  final TextEditingController loanDateController;
  final TextEditingController returnDateController;
  final TextEditingController purposeController;
  final TextEditingController notesController;
  final String repaymentType;
  final String todayFormatted;
  final String? Function(String?) validateAmount;
  final String? Function(String?) validateReturnDate;
  final VoidCallback onReturnDateTap;

  const ContractDetailsForm({
    super.key,
    required this.isSaving,
    required this.amountController,
    required this.loanDateController,
    required this.returnDateController,
    required this.purposeController,
    required this.notesController,
    required this.repaymentType,
    required this.todayFormatted,
    required this.validateAmount,
    required this.validateReturnDate,
    required this.onReturnDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContractFormStyles.buildSectionTitle('ข้อมูลสัญญา'),
        const SizedBox(height: 12),
        TextFormField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          enabled: !isSaving,
          decoration: const InputDecoration(
            labelText: 'จำนวนเงิน',
            hintText: 'เช่น 10000',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            suffixText: 'บาท',
            border: OutlineInputBorder(),
          ),
          validator: validateAmount,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: loanDateController,
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'วันให้กู้',
            helperText: 'กำหนดเป็นวันที่ปัจจุบันเท่านั้น และแก้ไขไม่ได้',
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: const OutlineInputBorder(),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'วันนี้คือ $todayFormatted',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: returnDateController,
          readOnly: true,
          enabled: !isSaving,
          onTap: isSaving ? null : onReturnDateTap,
          decoration: const InputDecoration(
            labelText: 'วันคืนเงิน',
            hintText: 'เลือกวันคืนเงิน',
            helperText: 'เลือกได้ตั้งแต่วันนี้เป็นต้นไป',
            prefixIcon: Icon(Icons.event_available_outlined),
            suffixIcon: Icon(Icons.calendar_month_outlined),
            border: OutlineInputBorder(),
          ),
          validator: validateReturnDate,
        ),
        const SizedBox(height: 22),
        ContractFormStyles.buildSectionTitle('รูปแบบการชำระเงิน'),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: repaymentType,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'รูปแบบการชำระเงิน (คำนวณอัตโนมัติ)',
            prefixIcon: Icon(Icons.payments_outlined),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
          ),
        ),
        const SizedBox(height: 22),
        ContractFormStyles.buildSectionTitle('รายละเอียดเพิ่มเติม'),
        const SizedBox(height: 12),
        TextFormField(
          controller: purposeController,
          enabled: !isSaving,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'วัตถุประสงค์การกู้',
            hintText: 'ระบุวัตถุประสงค์ เช่น ค่าใช้จ่ายส่วนตัว',
            prefixIcon: Icon(Icons.assignment_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          enabled: !isSaving,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'หมายเหตุ',
            hintText: 'รายละเอียดเพิ่มเติม',
            prefixIcon: Icon(Icons.notes_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ContractFormStyles.buildDateRuleCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}
